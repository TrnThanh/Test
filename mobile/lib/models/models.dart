class Restaurant {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? description;
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
