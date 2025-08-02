import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:emergency_sos/models/location_data.dart';
import 'package:emergency_sos/services/connectivity_service.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Database? _database;
  StreamSubscription<Position>? _locationSubscription;
  final StreamController<LocationData> _locationController =
      StreamController<LocationData>.broadcast();

  // Cache for offline maps
  final Map<String, Uint8List> _mapCache = {};
  final Set<String> _downloadedRegions = {};

  // Location tracking settings
  bool _isTracking = false;
  Duration _trackingInterval = const Duration(seconds: 30);
  LocationAccuracy _accuracy = LocationAccuracy.high;

  Stream<LocationData> get locationStream => _locationController.stream;

  // Initialize the service
  Future<void> initialize() async {
    await _initDatabase();
    await _checkPermissions();
    await _loadOfflineMaps();
  }

  // Database initialization
  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'location_history.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE location_history (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL,
            altitude REAL,
            speed REAL,
            heading REAL,
            timestamp TEXT NOT NULL,
            address TEXT,
            type TEXT NOT NULL,
            notes TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE nearby_services (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            distance REAL NOT NULL,
            address TEXT,
            phone TEXT,
            rating REAL,
            isOpen INTEGER,
            icon TEXT,
            timestamp TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE offline_maps (
            region TEXT PRIMARY KEY,
            data BLOB NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Permission handling
  Future<bool> _checkPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
    ].request();

    bool hasLocationPermission = statuses[Permission.location] ==
            PermissionStatus.granted ||
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted ||
        statuses[Permission.locationAlways] == PermissionStatus.granted;

    if (!hasLocationPermission) {
      throw Exception(
          'Location permissions are required for this app to function properly.');
    }

    return hasLocationPermission;
  }

  // Get current location with high accuracy
  Future<LocationData> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
        timeLimit: const Duration(seconds: 10),
      );

      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        // Address resolution failed, continue without it
      }

      final locationData = LocationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
        address: address,
        type: LocationType.current,
      );

      // Save to database
      await _saveLocationToDatabase(locationData);

      // Broadcast to stream
      _locationController.add(locationData);

      return locationData;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  // Start location tracking
  Future<void> startLocationTracking({
    Duration? interval,
    LocationAccuracy? accuracy,
  }) async {
    if (_isTracking) return;

    if (interval != null) _trackingInterval = interval;
    if (accuracy != null) _accuracy = accuracy;

    _isTracking = true;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: _accuracy,
        distanceFilter: 10, // Update every 10 meters
        timeLimit: const Duration(seconds: 10),
      ),
    ).listen(
      (Position position) async {
        String? address;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            address =
                '${place.street}, ${place.locality}, ${place.administrativeArea}';
          }
        } catch (e) {
          // Address resolution failed
        }

        final locationData = LocationData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
          address: address,
          type: LocationType.history,
        );

        await _saveLocationToDatabase(locationData);
        _locationController.add(locationData);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  // Stop location tracking
  Future<void> stopLocationTracking() async {
    _isTracking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // Save location to database
  Future<void> _saveLocationToDatabase(LocationData location) async {
    if (_database == null) return;

    await _database!.insert(
      'location_history',
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get location history
  Future<List<LocationData>> getLocationHistory({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    if (_database == null) return [];

    String whereClause = '';
    List<Object> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'timestamp BETWEEN ? AND ?';
      whereArgs = [startDate.toIso8601String(), endDate.toIso8601String()];
    } else if (startDate != null) {
      whereClause = 'timestamp >= ?';
      whereArgs = [startDate.toIso8601String()];
    } else if (endDate != null) {
      whereClause = 'timestamp <= ?';
      whereArgs = [endDate.toIso8601String()];
    }

    final List<Map<String, dynamic>> maps = await _database!.query(
      'location_history',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => LocationData.fromMap(map)).toList();
  }

  // Find nearby emergency services
  Future<List<NearbyService>> findNearbyServices({
    required double latitude,
    required double longitude,
    required String type,
    double radius = 5000, // 5km default
  }) async {
    try {
      // Check if we have internet connectivity
      bool isOnline = await _checkConnectivity();

      if (!isOnline) {
        // Return cached services if offline
        return await _getCachedNearbyServices(type);
      }

      // Use Google Places API to find nearby services
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
          'location=$latitude,$longitude&radius=$radius&type=$type'
          '&key=YOUR_GOOGLE_API_KEY', // Replace with actual API key
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        List<NearbyService> services = [];
        for (var result in results) {
          final service = NearbyService(
            id: result['place_id'],
            name: result['name'],
            type: type,
            latitude: (result['geometry']['location']['lat'] as num).toDouble(),
            longitude:
                (result['geometry']['location']['lng'] as num).toDouble(),
            distance: _calculateDistance(
              latitude,
              longitude,
              (result['geometry']['location']['lat'] as num).toDouble(),
              (result['geometry']['location']['lng'] as num).toDouble(),
            ),
            address: result['vicinity'],
            rating: result['rating']?.toDouble(),
            isOpen: result['opening_hours']?['open_now'] ?? true,
            icon: result['icon'],
          );
          services.add(service);
        }

        // Cache the results
        await _cacheNearbyServices(services);

        return services;
      } else {
        throw Exception('Failed to fetch nearby services');
      }
    } catch (e) {
      // Fallback to cached data
      return await _getCachedNearbyServices(type);
    }
  }

  // Calculate distance between two points
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(_degreesToRadians(lat1)) *
            sin(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Cache nearby services
  Future<void> _cacheNearbyServices(List<NearbyService> services) async {
    if (_database == null) return;

    for (var service in services) {
      await _database!.insert(
        'nearby_services',
        {
          ...service.toMap(),
          'timestamp': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Get cached nearby services
  Future<List<NearbyService>> _getCachedNearbyServices(String type) async {
    if (_database == null) return [];

    final List<Map<String, dynamic>> maps = await _database!.query(
      'nearby_services',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'distance ASC',
      limit: 20,
    );

    return maps.map((map) => NearbyService.fromMap(map)).toList();
  }

  // Check connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityService = ConnectivityService();
      return await connectivityService.hasInternetConnection();
    } catch (e) {
      return false;
    }
  }

  // Calculate route to destination
  Future<RouteInfo?> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    RouteType type = RouteType.driving,
    List<LatLng>? waypoints,
  }) async {
    try {
      bool isOnline = await _checkConnectivity();

      if (!isOnline) {
        // Return cached route if available
        return await _getCachedRoute(origin, destination, type);
      }

      // Use Google Directions API
      String waypointsParam = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsParam =
            '&waypoints=${waypoints.map((wp) => '${wp.latitude},${wp.longitude}').join('|')}';
      }

      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=${type.toString().split('.').last}'
          '$waypointsParam'
          '&key=YOUR_GOOGLE_API_KEY', // Replace with actual API key
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;

        if (routes.isNotEmpty) {
          final route = routes.first;
          final legs = route['legs'] as List;

          double totalDistance = 0;
          int totalDuration = 0;

          for (var leg in legs) {
            totalDistance += (leg['distance']['value'] as num).toDouble();
            totalDuration += (leg['duration']['value'] as num).toInt();
          }

          List<LatLng> routeWaypoints = [];
          if (route['overview_polyline'] != null) {
            // Decode polyline to get waypoints
            routeWaypoints =
                _decodePolyline(route['overview_polyline']['points']);
          }

          final routeInfo = RouteInfo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            waypoints: routeWaypoints,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            polyline: route['overview_polyline']?['points'],
            type: type,
            timestamp: DateTime.now(),
          );

          // Cache the route
          await _cacheRoute(routeInfo);

          return routeInfo;
        }
      }

      return null;
    } catch (e) {
      return await _getCachedRoute(origin, destination, type);
    }
  }

  // Decode Google polyline
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  // Cache route
  Future<void> _cacheRoute(RouteInfo route) async {
    // Implementation for caching routes
    // This would store the route in the database for offline access
  }

  // Get cached route
  Future<RouteInfo?> _getCachedRoute(
      LatLng origin, LatLng destination, RouteType type) async {
    // Implementation for retrieving cached routes
    return null;
  }

  // Download offline map for a region
  Future<void> downloadOfflineMap({
    required String region,
    required LatLng center,
    required double radius,
    int zoomLevels = 3,
  }) async {
    try {
      bool isOnline = await _checkConnectivity();
      if (!isOnline) {
        throw Exception(
            'Internet connection required to download offline maps');
      }

      // Download map tiles for the specified region
      for (int zoom = 10; zoom < 10 + zoomLevels; zoom++) {
        await _downloadMapTiles(region, center, radius, zoom);
      }

      _downloadedRegions.add(region);
      await _saveOfflineMapMetadata(region, center, radius, zoomLevels);
    } catch (e) {
      throw Exception('Failed to download offline map: $e');
    }
  }

  // Download map tiles for a specific zoom level
  Future<void> _downloadMapTiles(
      String region, LatLng center, double radius, int zoom) async {
    // Calculate tile bounds
    final bounds = _calculateTileBounds(center, radius, zoom);

    for (int x = bounds['minX']!; x <= bounds['maxX']!; x++) {
      for (int y = bounds['minY']!; y <= bounds['maxY']!; y++) {
        final tileKey = '$region/$zoom/$x/$y';

        if (!_mapCache.containsKey(tileKey)) {
          try {
            final response = await http.get(
              Uri.parse('https://tile.openstreetmap.org/$zoom/$x/$y.png'),
            );

            if (response.statusCode == 200) {
              _mapCache[tileKey] = response.bodyBytes;
              await _saveTileToDatabase(tileKey, response.bodyBytes);
            }
          } catch (e) {
            print('Failed to download tile $tileKey: $e');
          }
        }
      }
    }
  }

  // Calculate tile bounds for a region
  Map<String, int> _calculateTileBounds(
      LatLng center, double radius, int zoom) {
    // Convert lat/lng to tile coordinates
    int n = (1 << zoom);
    double latRad = center.latitude * (pi / 180);
    int x = ((center.longitude + 180) / 360 * n).floor();
    int y = ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();

    // Calculate radius in tiles (approximate)
    int radiusTiles = (radius /
            (156543.03392 * (cos(center.latitude * (pi / 180)) / (1 << zoom))))
        .ceil();

    return {
      'minX': (x - radiusTiles).clamp(0, n - 1),
      'maxX': (x + radiusTiles).clamp(0, n - 1),
      'minY': (y - radiusTiles).clamp(0, n - 1),
      'maxY': (y + radiusTiles).clamp(0, n - 1),
    };
  }

  // Save tile to database
  Future<void> _saveTileToDatabase(String tileKey, Uint8List data) async {
    if (_database == null) return;

    await _database!.insert(
      'offline_maps',
      {
        'region': tileKey,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Save offline map metadata
  Future<void> _saveOfflineMapMetadata(
      String region, LatLng center, double radius, int zoomLevels) async {
    // Implementation for saving metadata about downloaded regions
  }

  // Load offline maps from database
  Future<void> _loadOfflineMaps() async {
    if (_database == null) return;

    final List<Map<String, dynamic>> maps =
        await _database!.query('offline_maps');

    for (var map in maps) {
      final region = map['region'] as String;
      final data = map['data'] as Uint8List;
      _mapCache[region] = data;

      // Extract region name from tile key
      final parts = region.split('/');
      if (parts.isNotEmpty) {
        _downloadedRegions.add(parts[0]);
      }
    }
  }

  // Get offline map tile
  Uint8List? getOfflineMapTile(String region, int zoom, int x, int y) {
    final tileKey = '$region/$zoom/$x/$y';
    return _mapCache[tileKey];
  }

  // Check if region is available offline
  bool isRegionAvailableOffline(String region) {
    return _downloadedRegions.contains(region);
  }

  // Get list of downloaded regions
  Set<String> getDownloadedRegions() {
    return Set.from(_downloadedRegions);
  }

  // Clear location history
  Future<void> clearLocationHistory() async {
    if (_database == null) return;
    await _database!.delete('location_history');
  }

  // Clear offline maps
  Future<void> clearOfflineMaps() async {
    if (_database == null) return;
    await _database!.delete('offline_maps');
    _mapCache.clear();
    _downloadedRegions.clear();
  }

  // Dispose resources
  Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController.close();
    await _database?.close();
  }
}
