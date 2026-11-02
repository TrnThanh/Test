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
  final bool isSponsor;
  final double? rating;
  final double? adminRating;
  final bool isActive;
  final double? distanceMeters;
  final double? distanceKm;
  final List<String> serviceLicenses;
  final RestaurantRecommendation? recommendation;

  int? get categoryId => recommendation?.featuredDish.categoryId;

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
    this.isSponsor = false,
    this.rating,
    this.adminRating,
    this.isActive = true,
    this.distanceMeters,
    this.distanceKm,
    this.serviceLicenses = const [],
    this.recommendation,
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

    var rawLicenses = json['service_licenses'];
    List<String> licensesList = [];
    if (rawLicenses is List) {
      licensesList = rawLicenses.map((e) => e.toString()).toList();
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
      isSponsor: json['is_sponsor'] as bool? ?? false,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      adminRating: json['admin_rating'] != null ? (json['admin_rating'] as num).toDouble() : null,
      isActive: json['is_active'] as bool? ?? true,
      distanceMeters: distM,
      distanceKm: distKm,
      serviceLicenses: licensesList,
      recommendation: json['recommendation'] != null && json['recommendation'] is Map
          ? RestaurantRecommendation.fromJson(json['recommendation'] as Map<String, dynamic>)
          : null,
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
  final String sessionId;
  final String accessToken;

  RoleLoginResponse({
    required this.role,
    required this.id,
    required this.email,
    this.fullName,
    this.shopName,
    this.phone,
    required this.sessionId,
    String? accessToken,
  }) : accessToken = accessToken ?? sessionId;

  factory RoleLoginResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['data'] != null && json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final String sid = (json['session_id'] ??
        data['session_id'] ??
        json['access_token'] ??
        data['access_token'] ??
        '') as String;

    return RoleLoginResponse(
      role: json['role'] as String? ?? 'user',
      id: (data['id'] ?? json['id'] ?? 0) as int,
      email: (data['email'] ?? json['email'] ?? '') as String,
      fullName: (data['full_name'] ?? json['full_name']) as String?,
      shopName: (data['shop_name'] ?? json['shop_name']) as String?,
      phone: (data['phone'] ?? json['phone']) as String?,
      sessionId: sid,
      accessToken: sid,
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
  final int? restaurantId;
  final String name;
  final String? description;
  final int displayOrder;
  final bool isActive;
  final int dishCount;

  Category({
    required this.id,
    this.restaurantId,
    required this.name,
    this.description,
    this.displayOrder = 0,
    this.isActive = true,
    this.dishCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      restaurantId: json['restaurant_id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      dishCount: json['dish_count'] as int? ?? 0,
    );
  }
}

class MealTypeEntity {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? startTime;
  final String? endTime;
  final int sortOrder;
  final bool isActive;

  MealTypeEntity({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.startTime,
    this.endTime,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory MealTypeEntity.fromJson(Map<String, dynamic> json) {
    return MealTypeEntity(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class Weather {
  final int id;
  final String code;
  final String name;
  final String? description;
  final double? minTemp;
  final double? maxTemp;
  final int? minHumidity;
  final int? maxHumidity;
  final String? condition;
  final String? icon;
  final String? season;

  Weather({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.minTemp,
    this.maxTemp,
    this.minHumidity,
    this.maxHumidity,
    this.condition,
    this.icon,
    this.season,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      minTemp: (json['min_temp'] as num?)?.toDouble(),
      maxTemp: (json['max_temp'] as num?)?.toDouble(),
      minHumidity: json['min_humidity'] as int?,
      maxHumidity: json['max_humidity'] as int?,
      condition: json['condition'] as String?,
      icon: json['icon'] as String?,
      season: json['season'] as String?,
    );
  }
}

class CurrentWeather {
  final double temperature;
  final double? feelsLike;
  final int? humidity;
  final String condition;
  final String description;
  final String? icon;
  final String? iconUrl;
  final double latitude;
  final double longitude;
  final String? locationName;
  final bool isLive;

  CurrentWeather({
    required this.temperature,
    this.feelsLike,
    this.humidity,
    required this.condition,
    required this.description,
    this.icon,
    this.iconUrl,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.isLive = true,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toInt(),
      condition: json['condition'] as String? ?? 'Clear',
      description: json['description'] as String? ?? 'Trời đẹp',
      icon: json['icon'] as String?,
      iconUrl: json['icon_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'] as String?,
      isLive: json['is_live'] as bool? ?? true,
    );
  }
}

class Dish {
  final int id;
  final int restaurantId;
  final int? categoryId;
  final String? category;
  final String? categoryName;
  final int? mealTypeId;
  final String? mealTypeName;
  final String name;
  final double price;
  final int? calories;
  final String? description;
  final String? imageUrl;
  final int spicyLevel;
  final List<String> dietaryTags;
  final List<String> mealTypes;
  final List<String> allergens;
  final String mealType;
  final List<String> ingredients;
  final bool isAvailable;

  Dish({
    required this.id,
    required this.restaurantId,
    this.categoryId,
    this.category,
    this.categoryName,
    this.mealTypeId,
    this.mealTypeName,
    required this.name,
    required this.price,
    this.calories,
    this.description,
    this.imageUrl,
    this.spicyLevel = 0,
    this.dietaryTags = const [],
    this.mealTypes = const [],
    this.allergens = const [],
    this.mealType = 'all_day',
    this.ingredients = const [],
    this.isAvailable = true,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    var rawIngredients = json['ingredients'];
    List<String> ingredientsList = [];
    if (rawIngredients is List) {
      ingredientsList = rawIngredients.map((e) => e.toString()).toList();
    }

    var rawDietary = json['dietary_tags'];
    List<String> dietaryList = [];
    if (rawDietary is List) {
      dietaryList = rawDietary.map((e) => e.toString()).toList();
    }

    var rawMealTypes = json['meal_types'];
    List<String> mealTypesList = [];
    if (rawMealTypes is List) {
      mealTypesList = rawMealTypes.map((e) => e.toString()).toList();
    }

    var rawAllergens = json['allergens'];
    List<String> allergensList = [];
    if (rawAllergens is List) {
      allergensList = rawAllergens.map((e) => e.toString()).toList();
    }

    String derivedMealType = json['meal_type'] as String? ??
        (mealTypesList.isNotEmpty ? mealTypesList.first : 'all_day');

    return Dish(
      id: json['id'] as int,
      restaurantId: json['restaurant_id'] as int,
      categoryId: json['category_id'] as int?,
      category: json['category'] as String?,
      categoryName: json['category_name'] as String?,
      mealTypeId: json['meal_type_id'] as int?,
      mealTypeName: json['meal_type_name'] as String?,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      calories: json['calories'] as int?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      spicyLevel: json['spicy_level'] as int? ?? 0,
      dietaryTags: dietaryList,
      mealTypes: mealTypesList,
      allergens: allergensList,
      mealType: derivedMealType,
      ingredients: ingredientsList,
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

class OptionUser {
  final int id;
  final int userId;
  final int categoryId;
  final bool hide;
  final String createdAt;
  final String updatedAt;

  OptionUser({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.hide = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OptionUser.fromJson(Map<String, dynamic> json) {
    return OptionUser(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: json['category_id'] as int,
      hide: json['hide'] as bool? ?? true,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'hide': hide,
  };
}

class UserProfile {
  final int id;
  final int userId;
  final double? heightCm;
  final double? weightKg;
  final String? gender;
  final int? birthYear;
  final String? activityLevel;
  final String? targetGoal;
  final List<int> favoriteCategoryIds;
  final List<String> dietaryPreferences;
  final String? spicyTolerance;
  final List<String> allergies;
  final String? budgetRange;
  final bool isOnboarded;
  final String? onboardedAt;
  final double? bmi;
  final String? bmiCategory;

  UserProfile({
    required this.id,
    required this.userId,
    this.heightCm,
    this.weightKg,
    this.gender,
    this.birthYear,
    this.activityLevel,
    this.targetGoal,
    this.favoriteCategoryIds = const [],
    this.dietaryPreferences = const [],
    this.spicyTolerance,
    this.allergies = const [],
    this.budgetRange,
    this.isOnboarded = false,
    this.onboardedAt,
    this.bmi,
    this.bmiCategory,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<int> catIds = [];
    if (json['favorite_category_ids'] != null && json['favorite_category_ids'] is List) {
      catIds = (json['favorite_category_ids'] as List).map((e) => (e as num).toInt()).toList();
    }

    List<String> diets = [];
    if (json['dietary_preferences'] != null && json['dietary_preferences'] is List) {
      diets = (json['dietary_preferences'] as List).map((e) => e.toString()).toList();
    }

    List<String> algs = [];
    if (json['allergies'] != null && json['allergies'] is List) {
      algs = (json['allergies'] as List).map((e) => e.toString()).toList();
    }

    return UserProfile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      heightCm: json['height_cm'] != null ? (json['height_cm'] as num).toDouble() : null,
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      gender: json['gender'] as String?,
      birthYear: json['birth_year'] != null ? (json['birth_year'] as num).toInt() : null,
      activityLevel: json['activity_level'] as String?,
      targetGoal: json['target_goal'] as String?,
      favoriteCategoryIds: catIds,
      dietaryPreferences: diets,
      spicyTolerance: json['spicy_tolerance'] as String?,
      allergies: algs,
      budgetRange: json['budget_range'] as String?,
      isOnboarded: json['is_onboarded'] as bool? ?? false,
      onboardedAt: json['onboarded_at'] as String?,
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      bmiCategory: json['bmi_category'] as String?,
    );
  }

  Map<String, dynamic> toJson({bool completeOnboarding = false}) => {
    if (heightCm != null) 'height_cm': heightCm,
    if (weightKg != null) 'weight_kg': weightKg,
    if (gender != null) 'gender': gender,
    if (birthYear != null) 'birth_year': birthYear,
    if (activityLevel != null) 'activity_level': activityLevel,
    if (targetGoal != null) 'target_goal': targetGoal,
    'favorite_category_ids': favoriteCategoryIds,
    'dietary_preferences': dietaryPreferences,
    if (spicyTolerance != null) 'spicy_tolerance': spicyTolerance,
    'allergies': allergies,
    if (budgetRange != null) 'budget_range': budgetRange,
    'complete_onboarding': completeOnboarding,
  };
}





class FeaturedDish {
  final int id;
  final String name;
  final double price;
  final int? calories;
  final String? imageUrl;
  final int? categoryId;
  final List<String> dietaryTags;

  FeaturedDish({
    required this.id,
    required this.name,
    required this.price,
    this.calories,
    this.imageUrl,
    this.categoryId,
    this.dietaryTags = const [],
  });

  factory FeaturedDish.fromJson(Map<String, dynamic> json) {
    return FeaturedDish(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      categoryId: (json['category_id'] as num?)?.toInt(),
      dietaryTags: (json['dietary_tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class RestaurantRecommendation {
  final double score;
  final FeaturedDish featuredDish;
  final List<String> badges;
  final String? explanation;

  RestaurantRecommendation({
    required this.score,
    required this.featuredDish,
    this.badges = const [],
    this.explanation,
  });

  factory RestaurantRecommendation.fromJson(Map<String, dynamic> json) {
    return RestaurantRecommendation(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      featuredDish: FeaturedDish.fromJson(json['featured_dish'] as Map<String, dynamic>? ?? {}),
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      explanation: json['explanation'] as String?,
    );
  }
}

class RecommendationContext {
  final String mealPeriod;
  final String mealTimeRange;
  final String weatherDesc;
  final String targetCaloriesDisplay;
  final List<String> unverifiedAllergies;
  final String? guestNotice;
  final String disclaimer;

  RecommendationContext({
    required this.mealPeriod,
    required this.mealTimeRange,
    required this.weatherDesc,
    required this.targetCaloriesDisplay,
    this.unverifiedAllergies = const [],
    this.guestNotice,
    required this.disclaimer,
  });

  factory RecommendationContext.fromJson(Map<String, dynamic> json) {
    return RecommendationContext(
      mealPeriod: json['meal_period'] as String? ?? '',
      mealTimeRange: json['meal_time_range'] as String? ?? '',
      weatherDesc: json['weather_desc'] as String? ?? '',
      targetCaloriesDisplay: json['target_calories_display'] as String? ?? '',
      unverifiedAllergies: (json['unverified_allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      guestNotice: json['guest_notice'] as String?,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class ContextualRecommendation {
  final RecommendationContext context;
  final Restaurant? heroRestaurant;
  final List<Restaurant> recommendedRestaurants;

  ContextualRecommendation({
    required this.context,
    this.heroRestaurant,
    this.recommendedRestaurants = const [],
  });

  factory ContextualRecommendation.fromJson(Map<String, dynamic> json) {
    Restaurant? hero;
    if (json['hero_restaurant'] != null && json['hero_restaurant'] is Map) {
      hero = Restaurant.fromJson(json['hero_restaurant'] as Map<String, dynamic>);
    }
    List<Restaurant> list = [];
    if (json['recommended_restaurants'] != null && json['recommended_restaurants'] is List) {
      list = (json['recommended_restaurants'] as List)
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return ContextualRecommendation(
      context: RecommendationContext.fromJson(json['context'] as Map<String, dynamic>? ?? {}),
      heroRestaurant: hero,
      recommendedRestaurants: list,
    );
  }
}


class RestaurantRouteData {
  final int restaurantId;
  final String restaurantName;
  final double distanceMeters;
  final double durationSeconds;
  final List<List<double>> rawCoordinates; // [[lon, lat], ...]
  final bool isFallback;

  RestaurantRouteData({
    required this.restaurantId,
    required this.restaurantName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.rawCoordinates,
    required this.isFallback,
  });

  factory RestaurantRouteData.fromJson(Map<String, dynamic> json) {
    var rawCoords = json['coordinates'] as List? ?? [];
    List<List<double>> coords = [];
    for (var c in rawCoords) {
      if (c is List && c.length >= 2) {
        coords.add([
          (c[0] as num).toDouble(),
          (c[1] as num).toDouble(),
        ]);
      }
    }
    return RestaurantRouteData(
      restaurantId: json['restaurant_id'] as int? ?? 0,
      restaurantName: json['restaurant_name'] as String? ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0.0,
      rawCoordinates: coords,
      isFallback: json['is_fallback'] as bool? ?? false,
    );
  }
}
