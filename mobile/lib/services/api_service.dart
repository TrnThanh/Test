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

  Future<http.Response> _requestWithFallback(
    Future<http.Response> Function(String baseUrl) makeRequest,
  ) async {
    try {
      return await makeRequest(Env.baseUrl);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      final isConnError = errStr.contains('failed to fetch') ||
          errStr.contains('connection refused') ||
          errStr.contains('socketexception') ||
          errStr.contains('clientexception');
      if (isConnError) {
        final originalPort = Env.activePort;
        Env.switchPort();
        try {
          return await makeRequest(Env.baseUrl);
        } catch (_) {
          Env.activePort = originalPort;
          rethrow;
        }
      }
      rethrow;
    }
  }

  // ==============================================================================
  // PHAN HE 1: QUAN AN & NHA HANG (RESTAURANTS)
  // ==============================================================================

  // Lay danh sach tat ca quan an dang hoat dong trong he thong
  /// Goi API GET /restaurants de lay danh sach quan an theo phan trang [skip] va [limit].
  Future<List<Restaurant>> getRestaurants({int skip = 0, int limit = 200}) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/restaurants?skip=$skip&limit=$limit');
      return _client.get(uri).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tải danh sách quán: ${res.statusCode}');
  }

  // Tim kiem cac quan an xung quanh theo ban kinh khong gian PostGIS
  /// Goi API GET /restaurants/nearby voi toa do [lat], [lon] va ban kinh [radiusKm].
  Future<List<Restaurant>> getNearbyRestaurants({
    required double lat,
    required double lon,
    required double radiusKm,
  }) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/restaurants/nearby?lat=$lat&lon=$lon&radius_km=$radiusKm&limit=200');
      return _client.get(uri).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Restaurant.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Lỗi tìm kiếm quán lân cận: ${res.statusCode}');
  }

  Future<RestaurantRouteData> getRestaurantWalkingRoute({
    required int restaurantId,
    required double userLat,
    required double userLon,
  }) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse(
        '$base/restaurants/$restaurantId/route?user_lat=$userLat&user_lon=$userLon',
      );
      return _client.get(uri).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return RestaurantRouteData.fromJson(data);
    }
    _throwError(res);
  }


  // --- CONTEXT-AWARE RECOMMENDATION SYSTEM (CARS) ---
  Future<ContextualRecommendation?> getContextualRecommendations({
    required double lat,
    required double lon,
    int? userId,
    double? temp,
    String? weatherCode,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
    };
    if (userId != null) queryParams['user_id'] = userId.toString();
    if (temp != null) queryParams['temp'] = temp.toString();
    if (weatherCode != null) queryParams['weather_code'] = weatherCode;

    final queryString = Uri(queryParameters: queryParams).query;

    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/recommendations/contextual?$queryString');
      return _client.get(uri).timeout(const Duration(seconds: 10));
    });

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return ContextualRecommendation.fromJson(data);
    }
    return null;
  }

  Future<void> trackUserInteraction({
    int? userId,
    int? categoryId,
  }) async {
    if (userId != null && categoryId != null) {
      try {
        // Học ngầm: Ghi trực tiếp vào option_users với hide = true
        await setUserOption(userId, categoryId, true);
      } catch (_) {}
    }
  }

  // --- AUTH ---
  Future<RoleLoginResponse> loginUser(String email, String password) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/auth/user/login');
      return _client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
    });

    if (res.statusCode == 200) {
      return RoleLoginResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<RoleLoginResponse> registerUser(String email, String password, [String? fullName, String? phone, String? confirmPassword]) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/auth/user/register');
      return _client.post(
        uri,
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (confirmPassword != null && confirmPassword.isNotEmpty) 'confirm_password': confirmPassword,
        }),
      );
    });

    if (res.statusCode == 200 || res.statusCode == 201) {
      return RoleLoginResponse.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  // --- MAP GEOCODING ---
  Future<List<GeocodePlace>> searchMap(String query) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/map/search?q=${Uri.encodeComponent(query)}&limit=5');
      return _client.get(uri).timeout(const Duration(seconds: 8));
    });

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      final List places = data['places'] as List? ?? [];
      return places.map((e) => GeocodePlace.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<String> reverseMap(double lat, double lon) async {
    try {
      final res = await _requestWithFallback((base) {
        final uri = Uri.parse('$base/map/reverse?lat=$lat&lon=$lon');
        return _client.get(uri).timeout(const Duration(seconds: 8));
      });

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['display_name'] is String && (data['display_name'] as String).isNotEmpty) {
          return data['display_name'] as String;
        }
        if (data['address'] is Map) {
          final addrMap = data['address'] as Map;
          final parts = <String>[];
          for (final k in ['road', 'suburb', 'city_district', 'district', 'city', 'state']) {
            if (addrMap[k] != null && addrMap[k].toString().isNotEmpty) {
              parts.add(addrMap[k].toString());
            }
          }
          if (parts.isNotEmpty) return parts.join(', ');
        }
        return 'Vị trí của bạn';
      }
    } catch (_) {}

    // Fallback an toàn khi mạng hoặc server gián đoạn
    if (lat >= 20.5 && lat <= 21.6 && lon >= 105.2 && lon <= 106.3) {
      return 'Hà Nội, Việt Nam';
    }
    return 'Vị trí của bạn';
  }

  // --- WEATHER ---
  Future<CurrentWeather> getCurrentWeather({double? lat, double? lon}) async {
    final query = <String>[];
    if (lat != null) query.add('lat=$lat');
    if (lon != null) query.add('lon=$lon');
    final qStr = query.isNotEmpty ? '?${query.join('&')}' : '';

    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/weather/current$qStr');
      return _client.get(uri).timeout(const Duration(seconds: 8));
    });

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
      return CurrentWeather.fromJson(data);
    }
    throw Exception('Không thể lấy thông tin thời tiết');
  }

  // --- CATEGORIES ---
  Future<List<Category>> getRestaurantCategories(int restaurantId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/restaurants/$restaurantId/categories?is_active_only=true');
      return _client.get(uri);
    });
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
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/restaurants/$restaurantId/categories');
      return _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          if (description != null) 'description': description,
          'display_order': displayOrder,
        }),
      );
    });
    if (res.statusCode == 201) {
      return Category.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteCategory(int categoryId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/categories/$categoryId');
      return _client.delete(uri);
    });
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  Future<List<Category>> getAllCategories({bool isActiveOnly = true}) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/categories?is_active_only=$isActiveOnly');
      return _client.get(uri);
    });
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // --- DISHES ---
  Future<List<Dish>> getRestaurantDishes(int restaurantId, {int? categoryId}) async {
    final res = await _requestWithFallback((base) {
      String url = '$base/restaurants/$restaurantId/dishes';
      if (categoryId != null) {
        url += '?category_id=$categoryId';
      }
      return _client.get(Uri.parse(url));
    });
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Dish> createDish(int restaurantId, Map<String, dynamic> data) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/restaurants/$restaurantId/dishes');
      return _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    });
    if (res.statusCode == 201) {
      return Dish.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteDish(int dishId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/dishes/$dishId');
      return _client.delete(uri);
    });
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  // --- FAVOURITES ---
  Future<List<FavouriteDish>> getUserFavourites(int userId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/favourites');
      return _client.get(uri);
    });
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => FavouriteDish.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> addFavouriteDish(int userId, int dishId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/favourites/$dishId');
      return _client.post(uri);
    });
    if (res.statusCode == 200 || res.statusCode == 201) return;
    _throwError(res);
  }

  Future<void> removeFavouriteDish(int userId, int dishId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/favourites/$dishId');
      return _client.delete(uri);
    });
    if (res.statusCode == 200) return;
    _throwError(res);
  }

  Future<void> removeFavourite(int userId, int favId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/favourites/by-id/$favId');
      return _client.delete(uri);
    });
    if (res.statusCode == 200 || res.statusCode == 204) return;
    final res2 = await _requestWithFallback((base) {
      final fallbackUri = Uri.parse('$base/users/$userId/favourites/$favId');
      return _client.delete(fallbackUri);
    });
    if (res2.statusCode == 200 || res2.statusCode == 204) return;
    _throwError(res);
  }

  // --- USER OPTIONS (OptionUser) ---
  Future<List<OptionUser>> getUserOptions(int userId, {bool? hide}) async {
    final res = await _requestWithFallback((base) {
      String url = '$base/users/$userId/options';
      if (hide != null) {
        url += '?hide=$hide';
      }
      return _client.get(Uri.parse(url));
    });
    if (res.statusCode == 200) {
      final List list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return list.map((e) => OptionUser.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<OptionUser> setUserOption(int userId, int categoryId, bool hide) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/options');
      return _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category_id': categoryId, 'hide': hide}),
      );
    });
    if (res.statusCode == 200 || res.statusCode == 201) {
      return OptionUser.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<void> deleteUserOption(int userId, int optionId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/options/$optionId');
      return _client.delete(uri);
    });
    if (res.statusCode == 200 || res.statusCode == 204) return;
    _throwError(res);
  }

  Never _throwError(http.Response res) {
    String? message;
    try {
      final err = jsonDecode(utf8.decode(res.bodyBytes));
      if (err is Map) {
        final msg = err['detail'] ?? err['message'];
        if (msg != null && msg.toString().isNotEmpty) {
          message = msg.toString();
        }
      }
    } catch (_) {}

    if (res.statusCode == 401) {
      if (message != null &&
          (message.toLowerCase().contains('incorrect') ||
           message.toLowerCase().contains('sai') ||
           message.toLowerCase().contains('password') ||
           message.toLowerCase().contains('email'))) {
        throw Exception('Tài khoản hoặc mật khẩu không chính xác');
      }
      throw Exception(message ?? 'Tài khoản hoặc mật khẩu không chính xác');
    }

    if (message != null) {
      throw Exception(message);
    }
    if (res.statusCode == 403) {
      throw Exception('Bạn không có quyền thực hiện thao tác này');
    }
    if (res.statusCode == 404) {
      throw Exception('Không tìm thấy dữ liệu yêu cầu');
    }
    if (res.statusCode >= 500) {
      throw Exception('Máy chủ đang gặp sự cố (${res.statusCode}), vui lòng thử lại sau');
    }

    throw Exception('Lỗi máy chủ (${res.statusCode})');
  }
  // --- USER PROFILE & ONBOARDING ---
  Future<UserProfile> getUserProfile(int userId) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/profile');
      return _client.get(uri);
    });
    if (res.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  Future<UserProfile> updateUserProfile(int userId, Map<String, dynamic> data) async {
    final res = await _requestWithFallback((base) {
      final uri = Uri.parse('$base/users/$userId/profile');
      return _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
    });
    if (res.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    }
    _throwError(res);
  }

  // --- ALLERGENS ---
  Future<List<String>> getAllergens() async {
    try {
      final res = await _requestWithFallback((base) {
        final uri = Uri.parse('$base/allergens');
        return _client.get(uri).timeout(const Duration(seconds: 5));
      });
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
        return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {
      try {
        final res2 = await _requestWithFallback((base) {
          final uri = Uri.parse('$base/ingredients/allergens');
          return _client.get(uri).timeout(const Duration(seconds: 5));
        });
        if (res2.statusCode == 200) {
          final List<dynamic> data = jsonDecode(utf8.decode(res2.bodyBytes));
          return data.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return [];
  }

}
