import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class LocationData extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? address;
  final LocationType type;
  final String? notes;

  const LocationData({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    this.address,
    this.type = LocationType.current,
    this.notes,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      id: map['id'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      accuracy: map['accuracy']?.toDouble(),
      altitude: map['altitude']?.toDouble(),
      speed: map['speed']?.toDouble(),
      heading: map['heading']?.toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      address: map['address'],
      type: LocationType.values.firstWhere(
        (e) => e.toString() == 'LocationType.${map['type']}',
        orElse: () => LocationType.current,
      ),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
      'type': type.toString().split('.').last,
      'notes': notes,
    };
  }

  LocationData copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    String? address,
    LocationType? type,
    String? notes,
  }) {
    return LocationData(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      timestamp: timestamp ?? this.timestamp,
      address: address ?? this.address,
      type: type ?? this.type,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        accuracy,
        altitude,
        speed,
        heading,
        timestamp,
        address,
        type,
        notes,
      ];
}

enum LocationType {
  current,
  history,
  emergency,
  safeLocation,
  waypoint,
}

class NearbyService extends Equatable {
  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final double distance;
  final String? address;
  final String? phone;
  final double? rating;
  final bool isOpen;
  final String? icon;

  const NearbyService({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.address,
    this.phone,
    this.rating,
    this.isOpen = true,
    this.icon,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory NearbyService.fromMap(Map<String, dynamic> map) {
    return NearbyService(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      address: map['address'],
      phone: map['phone'],
      rating: map['rating']?.toDouble(),
      isOpen: map['isOpen'] ?? true,
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'address': address,
      'phone': phone,
      'rating': rating,
      'isOpen': isOpen,
      'icon': icon,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        latitude,
        longitude,
        distance,
        address,
        phone,
        rating,
        isOpen,
        icon,
      ];
}

class RouteInfo extends Equatable {
  final String id;
  final List<LatLng> waypoints;
  final double totalDistance;
  final int totalDuration;
  final String? polyline;
  final RouteType type;
  final DateTime timestamp;

  const RouteInfo({
    required this.id,
    required this.waypoints,
    required this.totalDistance,
    required this.totalDuration,
    this.polyline,
    required this.type,
    required this.timestamp,
  });

  factory RouteInfo.fromMap(Map<String, dynamic> map) {
    return RouteInfo(
      id: map['id'] ?? '',
      waypoints: (map['waypoints'] as List<dynamic>?)
              ?.map((point) => LatLng(
                    (point['latitude'] ?? 0.0).toDouble(),
                    (point['longitude'] ?? 0.0).toDouble(),
                  ))
              .toList() ??
          [],
      totalDistance: (map['totalDistance'] ?? 0.0).toDouble(),
      totalDuration: map['totalDuration'] ?? 0,
      polyline: map['polyline'],
      type: RouteType.values.firstWhere(
        (e) => e.toString() == 'RouteType.${map['type']}',
        orElse: () => RouteType.driving,
      ),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'waypoints': waypoints
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'polyline': polyline,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        waypoints,
        totalDistance,
        totalDuration,
        polyline,
        type,
        timestamp,
      ];
}

enum RouteType {
  driving,
  walking,
  bicycling,
  transit,
}
