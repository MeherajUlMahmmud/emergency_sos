import 'package:flutter/material.dart';
import 'package:emergency_sos/services/location_service.dart';

class OfflineMapsScreen extends StatefulWidget {
  static const String routeName = '/offline-maps';

  const OfflineMapsScreen({super.key});

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen> {
  final LocationService _locationService = LocationService();
  Set<String> _downloadedRegions = {};
  bool _isLoading = false;
  String? _currentDownloadingRegion;

  final List<MapRegion> _predefinedRegions = [
    MapRegion(
      name: 'Current City',
      description: 'Download maps for your current city area',
      radius: 5000, // 5km
      zoomLevels: 3,
      icon: Icons.location_city,
      color: Colors.blue,
    ),
    MapRegion(
      name: 'Metropolitan Area',
      description: 'Download maps for the entire metropolitan area',
      radius: 25000, // 25km
      zoomLevels: 4,
      icon: Icons.map,
      color: Colors.green,
    ),
    MapRegion(
      name: 'Emergency Zone',
      description: 'Download maps for emergency response areas',
      radius: 10000, // 10km
      zoomLevels: 3,
      icon: Icons.emergency,
      color: Colors.red,
    ),
    MapRegion(
      name: 'Travel Route',
      description: 'Download maps along your travel route',
      radius: 15000, // 15km
      zoomLevels: 3,
      icon: Icons.route,
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDownloadedRegions();
  }

  Future<void> _loadDownloadedRegions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final regions = _locationService.getDownloadedRegions();
      setState(() {
        _downloadedRegions = regions;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading offline maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadRegion(MapRegion region) async {
    try {
      // Get current location for the center point
      final currentLocation = await _locationService.getCurrentLocation();

      setState(() {
        _currentDownloadingRegion = region.name;
        _isLoading = true;
      });

      await _locationService.downloadOfflineMap(
        region: region.name,
        center: currentLocation.latLng,
        radius: region.radius.toDouble(),
        zoomLevels: region.zoomLevels,
      );

      setState(() {
        _downloadedRegions.add(region.name);
        _currentDownloadingRegion = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${region.name} downloaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _currentDownloadingRegion = null;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading ${region.name}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRegion(String regionName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline Map'),
        content: Text(
            'Are you sure you want to delete "$regionName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _locationService.clearOfflineMaps();
        setState(() {
          _downloadedRegions.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline maps cleared'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting offline maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          if (_downloadedRegions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _deleteRegion('all'),
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header information
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offline Maps',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Download maps for offline use during emergencies when internet connectivity may be limited.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Downloaded',
                        '${_downloadedRegions.length}',
                        Icons.download_done,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        'Available',
                        '${_predefinedRegions.length}',
                        Icons.map,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Available regions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _predefinedRegions.length,
                    itemBuilder: (context, index) {
                      final region = _predefinedRegions[index];
                      final isDownloaded =
                          _downloadedRegions.contains(region.name);
                      final isDownloading =
                          _currentDownloadingRegion == region.name;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: region.color,
                            child: Icon(
                              region.icon,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            region.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(region.description),
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
                                    '${(region.radius / 1000).toStringAsFixed(1)} km radius',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.zoom_in,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${region.zoomLevels} zoom levels',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isDownloading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : isDownloaded
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              _deleteRegion(region.name),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    )
                                  : ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _downloadRegion(region),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: region.color,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Download'),
                                    ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MapRegion {
  final String name;
  final String description;
  final int radius;
  final int zoomLevels;
  final IconData icon;
  final Color color;

  const MapRegion({
    required this.name,
    required this.description,
    required this.radius,
    required this.zoomLevels,
    required this.icon,
    required this.color,
  });
}
