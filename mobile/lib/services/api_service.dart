import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../models/models.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  // --- RESTAURANTS ---
  Future<List<Restaurant>> getRestaurants({int skip = 0, int limit = 50}) async {
    final uri = Uri.parse('${Env.baseUrl}/restaurants?skip=$skip&limit=$limit');
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tải danh sách quán: ${res.statusCode}');
  }

  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/restaurants/nearby?lat=$lat&lon=$lon&radius_km=$radiusKm');
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tìm kiếm quán lân cận: ${res.statusCode}');
  }

  // --- AUTH ---
  Future<RoleLoginResponse> loginUser(String email, String password) async {
    final uri = Uri.parse('${Env.baseUrl}/auth/user/login');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (res.statusCode == 200) {
      return RoleLoginResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<RoleLoginResponse> registerUser(String email, String password, [String? fullName]) async {
    final uri = Uri.parse('${Env.baseUrl}/auth/user/register');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return RoleLoginResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  // --- MAP GEOCODING ---
  Future<List<GeocodePlace>> searchMap(String query) async {
    final uri = Uri.parse('${Env.baseUrl}/map/search?q=${Uri.encodeComponent(query)}&limit=5');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final List places = data['places'] as List? ?? [];
      return places.map((e) => GeocodePlace.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<String> reverseMap(double lat, double lon) async {
    final uri = Uri.parse('${Env.baseUrl}/map/reverse?lat=$lat&lon=$lon');
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return data['address'] as String? ?? 'Không xác định';
    }
    throw Exception('Lỗi chuyển toạ độ');
  }

  // --- CATEGORIES ---
  Future<List<Category>> getRestaurantCategories(int restaurantId) async {
    final uri = Uri.parse('${Env.baseUrl}/restaurants/$restaurantId/categories?is_active_only=true');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Category> createCategory(
    int restaurantId,
    String name, {
    String? description,
    int displayOrder = 0,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/restaurants/$restaurantId/categories');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        'display_order': displayOrder,
      }),
    );
    if (res.statusCode == 201) {
      return Category.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteCategory(int categoryId) async {
    final uri = Uri.parse('${Env.baseUrl}/categories/$categoryId');
    final res = await _client.delete(uri);
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  // --- DISHES ---
  Future<List<Dish>> getRestaurantDishes(int restaurantId, {int? categoryId}) async {
    String url = '${Env.baseUrl}/restaurants/$restaurantId/dishes';
    if (categoryId != null) {
      url += '?category_id=$categoryId';
    }
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Dish> createDish(int restaurantId, Map<String, dynamic> data) async {
    final uri = Uri.parse('${Env.baseUrl}/restaurants/$restaurantId/dishes');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return Dish.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteDish(int dishId) async {
    final uri = Uri.parse('${Env.baseUrl}/dishes/$dishId');
    final res = await _client.delete(uri);
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  // --- FAVOURITES ---
  Future<List<FavouriteDish>> getUserFavourites(int userId) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/favourites');
    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => FavouriteDish.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> addFavouriteDish(int userId, int dishId) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/favourites/$dishId');
    final res = await _client.post(uri);
    if (res.statusCode == 200 || res.statusCode == 201) return;
    _throwError(res);
  }

  Future<void> removeFavouriteDish(int userId, int dishId) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/favourites/$dishId');
    final res = await _client.delete(uri);
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  Future<void> removeFavourite(int userId, int favId) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/favourites/by-id/$favId');
    final res = await _client.delete(uri);
    if (res.statusCode == 200 || res.statusCode == 204) return;
    final fallbackUri = Uri.parse('${Env.baseUrl}/users/$userId/favourites/$favId');
    final res2 = await _client.delete(fallbackUri);
    if (res2.statusCode == 200 || res2.statusCode == 204) return;
    _throwError(res);
  }

  // --- USER OPTIONS (OptionUser) ---
  Future<List<OptionUser>> getUserOptions(int userId, {bool? hide}) async {
    String url = '${Env.baseUrl}/users/$userId/options';
    if (hide != null) {
      url += '?hide=$hide';
    }
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => OptionUser.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<OptionUser> setUserOption(int userId, int categoryId, bool hide) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/options');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'category_id': categoryId, 'hide': hide}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return OptionUser.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteUserOption(int userId, int optionId) async {
    final uri = Uri.parse('${Env.baseUrl}/users/$userId/options/$optionId');
    final res = await _client.delete(uri);
    if (res.statusCode == 200 || res.statusCode == 204) return;
    _throwError(res);
  }

  Never _throwError(http.Response res) {
    try {
      final err = jsonDecode(utf8.decode(res.bodyBytes));
      if (err is Map && err['detail'] != null) {
        throw Exception(err['detail'].toString());
      }
    } catch (_) {}
    throw Exception('Lỗi máy chủ (${res.statusCode})');
  }
}
