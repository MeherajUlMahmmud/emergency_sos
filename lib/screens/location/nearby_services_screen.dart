import 'package:flutter/material.dart';
import 'package:emergency_sos/models/location_data.dart';
import 'package:emergency_sos/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyServicesScreen extends StatefulWidget {
  static const String routeName = '/nearby-services';

  const NearbyServicesScreen({super.key});

  @override
  State<NearbyServicesScreen> createState() => _NearbyServicesScreenState();
}

class _NearbyServicesScreenState extends State<NearbyServicesScreen> {
  final LocationService _locationService = LocationService();
  List<NearbyService> _services = [];
  bool _isLoading = false;
  String _selectedType = 'hospital';
  LocationData? _currentLocation;

  final Map<String, String> _serviceTypes = {
    'hospital': 'Hospitals',
    'police': 'Police Stations',
    'fire_station': 'Fire Stations',
    'pharmacy': 'Pharmacies',
    'ambulance': 'Ambulance Services',
    'gas_station': 'Gas Stations',
  };

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
      await _loadNearbyServices();
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

  Future<void> _loadNearbyServices() async {
    if (_currentLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final services = await _locationService.findNearbyServices(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        type: _selectedType,
        radius: 5000, // 5km radius
      );

      setState(() {
        _services = services;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading nearby services: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callService(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch phone app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getDirections(NearbyService service) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${service.latitude},${service.longitude}'
    );
    
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

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
        return Icons.local_fire_department;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'ambulance':
        return Icons.emergency;
      case 'gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.location_on;
    }
  }

  Color _getServiceColor(String type) {
    switch (type) {
      case 'hospital':
        return Colors.red;
      case 'police':
        return Colors.blue;
      case 'fire_station':
        return Colors.orange;
      case 'pharmacy':
        return Colors.green;
      case 'ambulance':
        return Colors.red;
      case 'gas_station':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Emergency Services'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyServices,
          ),
        ],
      ),
      body: Column(
        children: [
          // Service type selector
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _serviceTypes.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(
                        _getServiceIcon(entry.key),
                        color: _getServiceColor(entry.key),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedType = newValue;
                  });
                  _loadNearbyServices();
                }
              },
            ),
          ),

          // Current location display
          if (_currentLocation != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLocation!.address ?? 
                      'Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Services list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No services found nearby',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try changing the service type or location',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getServiceColor(service.type),
                                child: Icon(
                                  _getServiceIcon(service.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                service.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (service.address != null)
                                    Text(
                                      service.address!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.straighten,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDistance(service.distance),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (service.rating != null) ...[
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          service.rating!.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (service.phone != null)
                                    IconButton(
                                      icon: const Icon(Icons.phone, color: Colors.green),
                                      onPressed: () => _callService(service.phone!),
                                      tooltip: 'Call',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.directions, color: Colors.blue),
                                    onPressed: () => _getDirections(service),
                                    tooltip: 'Get Directions',
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showServiceDetails(service);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showServiceDetails(NearbyService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getServiceColor(service.type),
                  child: Icon(
                    _getServiceIcon(service.type),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _serviceTypes[service.type] ?? service.type,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (service.address != null) ...[
              _buildDetailRow(Icons.location_on, 'Address', service.address!),
              const SizedBox(height: 8),
            ],
                         _buildDetailRow(
               Icons.straighten,
               'Distance',
               _formatDistance(service.distance),
             ),
            if (service.rating != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.star,
                'Rating',
                '${service.rating!.toStringAsFixed(1)} / 5.0',
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (service.phone != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _callService(service.phone!);
                      },
                    ),
                  ),
                if (service.phone != null) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _getDirections(service);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
} 