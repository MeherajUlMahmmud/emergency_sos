import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:emergency_sos/models/location_data.dart';
import 'package:emergency_sos/services/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteToSafetyScreen extends StatefulWidget {
  static const String routeName = '/route-to-safety';

  const RouteToSafetyScreen({super.key});

  @override
  State<RouteToSafetyScreen> createState() => _RouteToSafetyScreenState();
}

class _RouteToSafetyScreenState extends State<RouteToSafetyScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LocationData? _currentLocation;
  RouteInfo? _currentRoute;
  List<NearbyService> _safeLocations = [];
  bool _isLoading = false;
  RouteType _selectedRouteType = RouteType.driving;
  NearbyService? _selectedDestination;

  final List<SafeLocation> _predefinedSafeLocations = [
    const SafeLocation(
      name: 'Nearest Hospital',
      type: 'hospital',
      icon: Icons.local_hospital,
      color: Colors.red,
    ),
    const SafeLocation(
      name: 'Nearest Police Station',
      type: 'police',
      icon: Icons.local_police,
      color: Colors.blue,
    ),
    const SafeLocation(
      name: 'Nearest Fire Station',
      type: 'fire_station',
      icon: Icons.local_fire_department,
      color: Colors.orange,
    ),
    const SafeLocation(
      name: 'Nearest Pharmacy',
      type: 'pharmacy',
      icon: Icons.local_pharmacy,
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentLocation = await _locationService.getCurrentLocation();
      await _loadSafeLocations();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSafeLocations() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<NearbyService> allServices = [];

      // Load different types of safe locations
      for (var safeLocation in _predefinedSafeLocations) {
        final services = await _locationService.findNearbyServices(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          type: safeLocation.type,
          radius: 10000, // 10km radius
        );

        if (services.isNotEmpty) {
          allServices.add(services.first); // Add the nearest one
        }
      }

      setState(() {
        _safeLocations = allServices;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading safe locations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateRoute(NearbyService destination) async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoading = true;
      _selectedDestination = destination;
    });

    try {
      final route = await _locationService.calculateRoute(
        origin: _currentLocation!.latLng,
        destination: destination.latLng,
        type: _selectedRouteType,
      );

      setState(() {
        _currentRoute = route;
      });

      if (route != null) {
        // Fit map to show the entire route
        _fitMapToRoute(route);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error calculating route: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fitMapToRoute(RouteInfo route) {
    if (route.waypoints.isEmpty) return;

    double minLat = route.waypoints.first.latitude;
    double maxLat = route.waypoints.first.latitude;
    double minLng = route.waypoints.first.longitude;
    double maxLng = route.waypoints.first.longitude;

    for (var point in route.waypoints) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    // Add some padding
    const padding = 0.01;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    _mapController.move(
      LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2),
      12.0,
    );
  }

  Future<void> _openInMaps() async {
    if (_selectedDestination == null) return;

    final Uri mapsUri = Uri.parse('https://www.google.com/maps/dir/?api=1'
        '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
        '&destination=${_selectedDestination!.latitude},${_selectedDestination!.longitude}'
        '&travelmode=${_selectedRouteType.toString().split('.').last}');

    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch maps app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      return '${(seconds / 60).round()} minutes';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).round();
      return '$hours hours $minutes minutes';
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route to Safety'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedDestination != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInMaps,
              tooltip: 'Open in Maps',
            ),
        ],
      ),
      body: Column(
        children: [
          // Route type selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Route Type: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<RouteType>(
                    value: _selectedRouteType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: RouteType.values.map((type) {
                      return DropdownMenuItem<RouteType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getRouteTypeIcon(type)),
                            const SizedBox(width: 8),
                            Text(type.toString().split('.').last.toUpperCase()),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (RouteType? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRouteType = newValue;
                        });
                        if (_selectedDestination != null) {
                          _calculateRoute(_selectedDestination!);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            flex: 2,
            child: _currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentLocation!.latLng,
                      initialZoom: 13,
                      onMapReady: () {
                        if (_currentRoute != null) {
                          _fitMapToRoute(_currentRoute!);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.emergency_sos',
                      ),
                      // Current location marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!.latLng,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                      // Safe locations markers
                      MarkerLayer(
                        markers: _safeLocations.map((service) {
                          final safeLocation =
                              _predefinedSafeLocations.firstWhere(
                            (sl) => sl.type == service.type,
                            orElse: () => SafeLocation(
                              name: 'Unknown',
                              type: service.type,
                              icon: Icons.location_on,
                              color: Colors.grey,
                            ),
                          );

                          return Marker(
                            point: service.latLng,
                            width: 30,
                            height: 30,
                            child: GestureDetector(
                              onTap: () => _calculateRoute(service),
                              child: Icon(
                                safeLocation.icon,
                                color: safeLocation.color,
                                size: 30,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Route polyline
                      if (_currentRoute != null &&
                          _currentRoute!.waypoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _currentRoute!.waypoints,
                              strokeWidth: 4,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                    ],
                  ),
          ),

          // Safe locations list
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Safe Locations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _safeLocations.isEmpty
                            ? const Center(
                                child: Text(
                                  'No safe locations found nearby',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _safeLocations.length,
                                itemBuilder: (context, index) {
                                  final service = _safeLocations[index];
                                  final safeLocation =
                                      _predefinedSafeLocations.firstWhere(
                                    (sl) => sl.type == service.type,
                                    orElse: () => SafeLocation(
                                      name: 'Unknown',
                                      type: service.type,
                                      icon: Icons.location_on,
                                      color: Colors.grey,
                                    ),
                                  );

                                  final isSelected =
                                      _selectedDestination?.id == service.id;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    color:
                                        isSelected ? Colors.blue.shade50 : null,
                                    child: ListTile(
                                      leading: Icon(
                                        safeLocation.icon,
                                        color: safeLocation.color,
                                      ),
                                      title: Text(
                                        service.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${_formatDistance(service.distance)} away',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      trailing: _currentRoute != null &&
                                              isSelected
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  _formatDuration(_currentRoute!
                                                      .totalDuration),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  _formatDistance(_currentRoute!
                                                      .totalDistance),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : null,
                                      onTap: () => _calculateRoute(service),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRouteTypeIcon(RouteType type) {
    switch (type) {
      case RouteType.driving:
        return Icons.directions_car;
      case RouteType.walking:
        return Icons.directions_walk;
      case RouteType.bicycling:
        return Icons.directions_bike;
      case RouteType.transit:
        return Icons.directions_bus;
    }
  }
}

class SafeLocation {
  final String name;
  final String type;
  final IconData icon;
  final Color color;

  const SafeLocation({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });
}
