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

  Future<RoleLoginResponse> loginSeller(String email, String password) async {
    final uri = Uri.parse('${Env.baseUrl}/auth/seller/login');
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

  Future<RoleLoginResponse> registerSeller({
    required String email,
    required String password,
    required String shopName,
    String? fullName,
    String? phone,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/auth/seller/register');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'email': email,
        'password': password,
        'shop_name': shopName,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return RoleLoginResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  // --- SELLER CRUD ---
  Future<List<Restaurant>> getSellerRestaurants(int sellerId) async {
    final uri = Uri.parse('${Env.baseUrl}/sellers/$sellerId/restaurants');
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tải quán của seller: ${res.statusCode}');
  }

  Future<Restaurant> createSellerRestaurant(
    int sellerId, {
    required String name,
    required double latitude,
    required double longitude,
    String? address,
    String? phone,
    String? description,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/sellers/$sellerId/restaurants');
    final res = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (description != null) 'description': description,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Restaurant.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<Restaurant> updateSellerRestaurant(
    int sellerId,
    int restaurantId, {
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    String? phone,
    String? description,
  }) async {
    final uri = Uri.parse('${Env.baseUrl}/sellers/$sellerId/restaurants/$restaurantId');
    final res = await _client.put(
      uri,
      headers: _headers(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (description != null) 'description': description,
      }),
    );

    if (res.statusCode == 200) {
      return Restaurant.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteSellerRestaurant(int sellerId, int restaurantId) async {
    final uri = Uri.parse('${Env.baseUrl}/sellers/$sellerId/restaurants/$restaurantId');
    final res = await _client.delete(uri);

    if (res.statusCode == 200 || res.statusCode == 204) {
      return;
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
