import 'package:flutter/material.dart';
import '../../models/emergency_history.dart';
import '../../services/emergency_service.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/error_widgets.dart';

class EmergencyHistoryScreen extends StatefulWidget {
  static const String routeName = '/emergency-history';

  const EmergencyHistoryScreen({super.key});

  @override
  State<EmergencyHistoryScreen> createState() => _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState extends State<EmergencyHistoryScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyHistory> _history = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final history = await _emergencyService.getEmergencyHistory();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency History'),
        actions: [
          IconButton(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LoadingWidgets.overlayLoading(
        isLoading: _isLoading,
        message: 'Loading history...',
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return ErrorWidgets.generalError(
        message: _errorMessage,
        onRetry: _loadHistory,
      );
    }

    if (_history.isEmpty) {
      return ErrorWidgets.emptyState(
        message:
            'No emergency history found.\nYour emergency activations will appear here.',
        title: 'No History',
        icon: Icons.history,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final emergency = _history[index];
        return _buildHistoryCard(emergency);
      },
    );
  }

  Widget _buildHistoryCard(EmergencyHistory emergency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEmergencyDetails(emergency),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: emergency.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      emergency.typeIcon,
                      color: emergency.statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emergency.typeDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          emergency.statusDisplayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: emergency.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: emergency.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      emergency.durationText,
                      style: TextStyle(
                        fontSize: 12,
                        color: emergency.statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (emergency.location != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        emergency.location!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(emergency.activatedAt),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (emergency.resolvedAt != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.check_circle,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(emergency.resolvedAt!),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              if (emergency.contactedNumbers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${emergency.contactedNumbers.length} contacts notified',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDetails(EmergencyHistory emergency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildEmergencyDetailsSheet(emergency),
    );
  }

  Widget _buildEmergencyDetailsSheet(EmergencyHistory emergency) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: emergency.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  emergency.typeIcon,
                  color: emergency.statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emergency.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      emergency.statusDisplayName,
                      style: TextStyle(
                        fontSize: 16,
                        color: emergency.statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Status', emergency.statusDisplayName),
          _buildDetailRow('Duration', emergency.durationText),
          _buildDetailRow('Activated', _formatDateTime(emergency.activatedAt)),
          if (emergency.resolvedAt != null)
            _buildDetailRow('Resolved', _formatDateTime(emergency.resolvedAt!)),
          if (emergency.location != null)
            _buildDetailRow('Location', emergency.location!),
          if (emergency.description != null)
            _buildDetailRow('Description', emergency.description!),
          if (emergency.notes != null)
            _buildDetailRow('Notes', emergency.notes!),
          if (emergency.contactedNumbers.isNotEmpty) ...[
            _buildDetailRow('Contacts Notified',
                emergency.contactedNumbers.length.toString()),
            const SizedBox(height: 8),
            Text(
              'Contacted Numbers:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            ...emergency.contactedNumbers.map((number) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    number,
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ],
          const SizedBox(height: 24),
          if (emergency.status == EmergencyStatus.active) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _emergencyService.resolveEmergency(emergency.id);
                        Navigator.pop(context);
                        _loadHistory();
                        ErrorWidgets.snackBarSuccess(
                          context: context,
                          message: 'Emergency marked as resolved!',
                        );
                      } catch (e) {
                        ErrorWidgets.snackBarError(
                          context: context,
                          message:
                              'Failed to resolve emergency: ${e.toString()}',
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
