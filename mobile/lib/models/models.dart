class Restaurant {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? description;
  final String? openTime;
  final String? closeTime;
  final double latitude;
  final double longitude;
  final int sellerId;
  final bool isActive;
  final double? distanceMeters;
  final double? distanceKm;

  Restaurant({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.description,
    this.openTime,
    this.closeTime,
    required this.latitude,
    required this.longitude,
    required this.sellerId,
    required this.isActive,
    this.distanceMeters,
    this.distanceKm,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    double? distKm;
    double? distM;

    if (json['distance_km'] != null) {
      distKm = (json['distance_km'] as num).toDouble();
      distM = distKm * 1000;
    } else if (json['distance_meters'] != null) {
      distM = (json['distance_meters'] as num).toDouble();
      distKm = distM / 1000;
    }

    return Restaurant(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sellerId: json['seller_id'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
      distanceMeters: distM,
      distanceKm: distKm,
    );
  }
}

class RoleLoginResponse {
  final String role;
  final int id;
  final String email;
  final String? fullName;
  final String? shopName;
  final String? phone;
  final String accessToken;

  RoleLoginResponse({
    required this.role,
    required this.id,
    required this.email,
    this.fullName,
    this.shopName,
    this.phone,
    required this.accessToken,
  });

  factory RoleLoginResponse.fromJson(Map<String, dynamic> json) {
    return RoleLoginResponse(
      role: json['role'] as String? ?? 'user',
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      shopName: json['shop_name'] as String?,
      phone: json['phone'] as String?,
      accessToken: json['access_token'] as String? ?? '',
    );
  }
}

class GeocodePlace {
  final String displayName;
  final double latitude;
  final double longitude;

  GeocodePlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodePlace.fromJson(Map<String, dynamic> json) {
    return GeocodePlace(
      displayName: json['display_name'] as String? ?? json['address'] as String? ?? 'Địa điểm',
      latitude: (json['latitude'] ?? json['lat'] as num).toDouble(),
      longitude: (json['longitude'] ?? json['lon'] as num).toDouble(),
    );
  }
}

class Category {
  final int id;
  final int restaurantId;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final int dishCount;

  Category({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    this.dishCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      restaurantId: json['restaurant_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      dishCount: json['dish_count'] as int? ?? 0,
    );
  }
}

class Dish {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String? category;
  final String? categoryName;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final String mealType;
  final List<String> tags;
  final bool isAvailable;

  Dish({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    this.category,
    this.categoryName,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.mealType = 'all_day',
    this.tags = const [],
    this.isAvailable = true,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    var rawTags = json['tags'];
    List<String> tagsList = [];
    if (rawTags is List) {
      tagsList = rawTags.map((e) => e.toString()).toList();
    }
    return Dish(
      id: json['id'] as int,
      restaurantId: json['restaurant_id'] as int,
      categoryId: json['category_id'] as int?,
      category: json['category'] as String?,
      categoryName: json['category_name'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      mealType: json['meal_type'] as String? ?? 'all_day',
      tags: tagsList,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

class FavouriteDish {
  final int id;
  final int userId;
  final int dishId;
  final String createdAt;
  final Dish? dish;

  FavouriteDish({
    required this.id,
    required this.userId,
    required this.dishId,
    required this.createdAt,
    this.dish,
  });

  factory FavouriteDish.fromJson(Map<String, dynamic> json) {
    return FavouriteDish(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      dishId: json['dish_id'] as int,
      createdAt: json['created_at'] as String? ?? '',
      dish: json['dish'] != null ? Dish.fromJson(json['dish'] as Map<String, dynamic>) : null,
    );
  }
}

