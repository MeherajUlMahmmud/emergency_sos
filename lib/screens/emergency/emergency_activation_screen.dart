import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/emergency_history.dart';
import '../../models/emergency_message.dart';
import '../../services/emergency_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/error_widgets.dart';

class EmergencyActivationScreen extends StatefulWidget {
  static const String routeName = '/emergency-activation';

  const EmergencyActivationScreen({super.key});

  @override
  State<EmergencyActivationScreen> createState() =>
      _EmergencyActivationScreenState();
}

class _EmergencyActivationScreenState extends State<EmergencyActivationScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  EmergencyType _selectedType = EmergencyType.other;
  String? _description;
  bool _isActivating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Activation'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: LoadingWidgets.overlayLoading(
        isLoading: _isActivating,
        message: 'Activating emergency...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildEmergencyTypeSelector(),
              const SizedBox(height: 24),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildActivationMethods(),
              const SizedBox(height: 24),
              _buildEmergencyPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: EmergencyType.values.length,
              itemBuilder: (context, index) {
                final type = EmergencyType.values[index];
                final isSelected = type == _selectedType;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryRed.withOpacity(0.1)
                          : null,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryRed
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getEmergencyTypeIcon(type),
                          size: 32,
                          color: isSelected
                              ? AppTheme.primaryRed
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmergencyTypeName(type),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryRed
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the emergency situation...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _description = value.isEmpty ? null : value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activation Methods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivationButton(
              icon: Icons.emergency,
              title: 'Immediate SOS',
              subtitle: 'Activate emergency immediately',
              color: AppTheme.primaryRed,
              onPressed: () => _activateEmergency(),
            ),
            const SizedBox(height: 12),
            _buildActivationButton(
              icon: Icons.timer,
              title: '3-Second Countdown',
              subtitle: 'Activate with 3-second delay',
              color: AppTheme.accentOrange,
              onPressed: () => _activateEmergencyWithCountdown(),
            ),
            const SizedBox(height: 12),
            _buildActivationButton(
              icon: Icons.vibration,
              title: 'Shake to Activate',
              subtitle: 'Shake device to activate',
              color: AppTheme.infoBlue,
              onPressed: () => _showShakeActivation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildEmergencyPreview() {
    final message = EmergencyMessage.getMessageForType(_selectedType);
    final previewMessage = message.formatMessage(
      location: 'Current Location',
      latitude: 0.0,
      longitude: 0.0,
      userName: 'User',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Message Preview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                previewMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateEmergency() async {
    await _performEmergencyActivation();
  }

  Future<void> _activateEmergencyWithCountdown() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCountdownDialog(),
    );
  }

  Widget _buildCountdownDialog() {
    return AlertDialog(
      title: const Text('Emergency Activation'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Emergency will be activated in:'),
          SizedBox(height: 16),
          Text(
            '3',
            style: TextStyle(
                fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showShakeActivation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shake to Activate'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vibration, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text('Shake your device to activate emergency'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activateEmergency();
            },
            child: const Text('Activate Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _performEmergencyActivation() async {
    try {
      setState(() {
        _isActivating = true;
      });

      // Haptic feedback
      HapticFeedback.heavyImpact();

      await _emergencyService.activateEmergency(
        type: _selectedType,
        description: _description,
      );

      setState(() {
        _isActivating = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Emergency Activated'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green),
                SizedBox(height: 16),
                Text('Emergency services and contacts have been notified.'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isActivating = false;
      });

      if (mounted) {
        ErrorWidgets.snackBarError(
          context: context,
          message: 'Failed to activate emergency: ${e.toString()}',
        );
      }
    }
  }

  IconData _getEmergencyTypeIcon(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return Icons.medical_services;
      case EmergencyType.accident:
        return Icons.car_crash;
      case EmergencyType.fire:
        return Icons.local_fire_department;
      case EmergencyType.crime:
        return Icons.security;
      case EmergencyType.naturalDisaster:
        return Icons.nature;
      case EmergencyType.other:
        return Icons.emergency;
    }
  }

  String _getEmergencyTypeName(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return 'Medical';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.fire:
        return 'Fire';
      case EmergencyType.crime:
        return 'Crime';
      case EmergencyType.naturalDisaster:
        return 'Natural\nDisaster';
      case EmergencyType.other:
        return 'Other';
    }
  }
}
