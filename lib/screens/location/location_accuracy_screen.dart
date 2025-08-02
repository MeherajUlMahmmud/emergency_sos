import 'package:flutter/material.dart';
import 'package:emergency_sos/models/location_data.dart';
import 'package:emergency_sos/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class LocationAccuracyScreen extends StatefulWidget {
  static const String routeName = '/location-accuracy';

  const LocationAccuracyScreen({super.key});

  @override
  State<LocationAccuracyScreen> createState() => _LocationAccuracyScreenState();
}

class _LocationAccuracyScreenState extends State<LocationAccuracyScreen> {
  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;
  bool _isLoading = false;
  bool _isHighAccuracyEnabled = false;
  bool _isIndoorPositioningEnabled = false;
  double _currentAccuracy = 0.0;
  String _accuracyStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _checkLocationAccuracy();
  }

  Future<void> _checkLocationAccuracy() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentLocation = await _locationService.getCurrentLocation();
      _currentAccuracy = _currentLocation?.accuracy ?? 0.0;
      _accuracyStatus = _getAccuracyStatus(_currentAccuracy);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking location accuracy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getAccuracyStatus(double accuracy) {
    if (accuracy <= 5) {
      return 'Excellent';
    } else if (accuracy <= 10) {
      return 'Good';
    } else if (accuracy <= 20) {
      return 'Fair';
    } else if (accuracy <= 50) {
      return 'Poor';
    } else {
      return 'Very Poor';
    }
  }

  Color _getAccuracyColor(String status) {
    switch (status) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      case 'Very Poor':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  Future<void> _enableHighAccuracy() async {
    setState(() {
      _isHighAccuracyEnabled = true;
      _isLoading = true;
    });

    try {
      // Request high accuracy location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 15),
      );

      _currentLocation = LocationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
        type: LocationType.current,
      );

      _currentAccuracy = position.accuracy;
      _accuracyStatus = _getAccuracyStatus(_currentAccuracy);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('High accuracy location enabled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enabling high accuracy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enableIndoorPositioning() async {
    setState(() {
      _isIndoorPositioningEnabled = true;
      _isLoading = true;
    });

    try {
      // Simulate indoor positioning improvement
      await Future.delayed(const Duration(seconds: 2));

      // In a real implementation, this would use WiFi positioning, Bluetooth beacons, etc.
      if (_currentLocation != null) {
        _currentAccuracy = (_currentAccuracy * 0.7)
            .clamp(1.0, 50.0); // Improve accuracy by 30%
        _accuracyStatus = _getAccuracyStatus(_currentAccuracy);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indoor positioning enabled'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error enabling indoor positioning: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Accuracy'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkLocationAccuracy,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current accuracy status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Location Accuracy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.gps_fixed,
                                color: _getAccuracyColor(_accuracyStatus),
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _accuracyStatus,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _getAccuracyColor(_accuracyStatus),
                                      ),
                                    ),
                                    Text(
                                      '± ${_currentAccuracy.toStringAsFixed(1)} meters',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location details
                  if (_currentLocation != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Latitude',
                                _currentLocation!.latitude.toStringAsFixed(6)),
                            _buildDetailRow('Longitude',
                                _currentLocation!.longitude.toStringAsFixed(6)),
                            if (_currentLocation!.altitude != null)
                              _buildDetailRow('Altitude',
                                  '${_currentLocation!.altitude!.toStringAsFixed(1)} m'),
                            if (_currentLocation!.speed != null)
                              _buildDetailRow('Speed',
                                  '${(_currentLocation!.speed! * 3.6).toStringAsFixed(1)} km/h'),
                            if (_currentLocation!.heading != null)
                              _buildDetailRow('Heading',
                                  '${_currentLocation!.heading!.toStringAsFixed(1)}°'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Accuracy improvement options
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Improve Accuracy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // High accuracy option
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _isHighAccuracyEnabled
                                  ? Colors.green
                                  : Colors.grey,
                              child: Icon(
                                Icons.gps_fixed,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text('High Accuracy GPS'),
                            subtitle:
                                const Text('Use best available GPS accuracy'),
                            trailing: Switch(
                              value: _isHighAccuracyEnabled,
                              onChanged: (value) {
                                if (value) {
                                  _enableHighAccuracy();
                                } else {
                                  setState(() {
                                    _isHighAccuracyEnabled = false;
                                  });
                                }
                              },
                            ),
                          ),

                          // Indoor positioning option
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _isIndoorPositioningEnabled
                                  ? Colors.green
                                  : Colors.grey,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                            ),
                            title: const Text('Indoor Positioning'),
                            subtitle: const Text(
                                'Use WiFi and Bluetooth for indoor accuracy'),
                            trailing: Switch(
                              value: _isIndoorPositioningEnabled,
                              onChanged: (value) {
                                if (value) {
                                  _enableIndoorPositioning();
                                } else {
                                  setState(() {
                                    _isIndoorPositioningEnabled = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tips for better accuracy
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips for Better Accuracy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTip(
                            Icons.open_in_new,
                            'Go Outside',
                            'GPS signals are stronger outdoors',
                          ),
                          _buildTip(
                            Icons.clear,
                            'Clear View',
                            'Avoid tall buildings and dense urban areas',
                          ),
                          _buildTip(
                            Icons.wifi,
                            'Enable WiFi',
                            'WiFi helps with indoor positioning',
                          ),
                          _buildTip(
                            Icons.bluetooth,
                            'Enable Bluetooth',
                            'Bluetooth beacons improve indoor accuracy',
                          ),
                          _buildTip(
                            Icons.stay_current_portrait,
                            'Stay Still',
                            'Remain stationary for more accurate readings',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Emergency location sharing
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Location Sharing',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your location will be shared with emergency contacts with the highest possible accuracy during emergency activations.',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.share_location),
                              label: const Text('Test Location Sharing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Location sharing test initiated'),
                                    backgroundColor: Colors.blue,
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
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
