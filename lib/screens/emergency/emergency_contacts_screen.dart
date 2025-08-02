import 'package:flutter/material.dart';
import '../../models/emergency_contact.dart';
import '../../services/emergency_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/error_widgets.dart';

class EmergencyContactsScreen extends StatefulWidget {
  static const String routeName = '/emergency-contacts';

  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyService _emergencyService = EmergencyService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final contacts = await _emergencyService.getEmergencyContacts();
      setState(() {
        _contacts = contacts;
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
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            onPressed: () => _showAddContactDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: LoadingWidgets.overlayLoading(
        isLoading: _isLoading,
        message: 'Loading contacts...',
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
        backgroundColor: AppTheme.primaryRed,
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return ErrorWidgets.generalError(
        message: _errorMessage,
        onRetry: _loadContacts,
      );
    }

    if (_contacts.isEmpty) {
      return ErrorWidgets.emptyState(
        message:
            'No emergency contacts added yet.\nTap the + button to add your first contact.',
        title: 'No Contacts',
        icon: Icons.people_outline,
        actionText: 'Add Contact',
        onAction: () => _showAddContactDialog(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(EmergencyContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.priorityColor.withOpacity(0.2),
          child: Icon(
            contact.categoryIcon,
            color: contact.priorityColor,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: contact.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.priorityDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: contact.priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contact.categoryDisplayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleContactAction(value, contact),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'call',
              child: Row(
                children: [
                  Icon(Icons.call),
                  SizedBox(width: 8),
                  Text('Call'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  void _handleContactAction(String action, EmergencyContact contact) {
    switch (action) {
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'call':
        _callContact(contact);
        break;
      case 'delete':
        _showDeleteConfirmation(contact);
        break;
    }
  }

  void _showContactDetails(EmergencyContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildContactDetailsSheet(contact),
    );
  }

  Widget _buildContactDetailsSheet(EmergencyContact contact) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: contact.priorityColor.withOpacity(0.2),
                child: Icon(
                  contact.categoryIcon,
                  size: 30,
                  color: contact.priorityColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      contact.phoneNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Category', contact.categoryDisplayName),
          _buildDetailRow('Priority', contact.priorityDisplayName),
          if (contact.relationship != null)
            _buildDetailRow('Relationship', contact.relationship!),
          if (contact.notes != null) _buildDetailRow('Notes', contact.notes!),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _callContact(contact);
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditContactDialog(contact);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
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
            width: 100,
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

  void _showAddContactDialog() {
    _showContactDialog();
  }

  void _showEditContactDialog(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController =
        TextEditingController(text: contact?.phoneNumber ?? '');
    final relationshipController =
        TextEditingController(text: contact?.relationship ?? '');
    final notesController = TextEditingController(text: contact?.notes ?? '');

    ContactCategory selectedCategory =
        contact?.category ?? ContactCategory.family;
    ContactPriority selectedPriority =
        contact?.priority ?? ContactPriority.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Contact' : 'Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContactCategory>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: ContactCategory.values.map((category) {
                    final contact = EmergencyContact(
                      id: '',
                      name: '',
                      phoneNumber: '',
                      category: category,
                      priority: ContactPriority.medium,
                      createdAt: DateTime.now(),
                    );
                    return DropdownMenuItem(
                      value: category,
                      child: Text(contact.categoryDisplayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ContactPriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: ContactPriority.values.map((priority) {
                    final contact = EmergencyContact(
                      id: '',
                      name: '',
                      phoneNumber: '',
                      category: ContactCategory.family,
                      priority: priority,
                      createdAt: DateTime.now(),
                    );
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(contact.priorityDisplayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship (Optional)',
                    prefixIcon: Icon(Icons.people),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ErrorWidgets.snackBarError(
                    context: context,
                    message: 'Please fill in all required fields',
                  );
                  return;
                }

                final newContact = EmergencyContact(
                  id: contact?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  category: selectedCategory,
                  priority: selectedPriority,
                  relationship: relationshipController.text.trim().isEmpty
                      ? null
                      : relationshipController.text.trim(),
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  createdAt: contact?.createdAt ?? DateTime.now(),
                );

                try {
                  if (isEditing) {
                    await _emergencyService.updateEmergencyContact(newContact);
                  } else {
                    await _emergencyService.addEmergencyContact(newContact);
                  }

                  Navigator.pop(context);
                  _loadContacts();

                  ErrorWidgets.snackBarSuccess(
                    context: context,
                    message: isEditing
                        ? 'Contact updated successfully!'
                        : 'Contact added successfully!',
                  );
                } catch (e) {
                  ErrorWidgets.snackBarError(
                    context: context,
                    message: 'Failed to save contact: ${e.toString()}',
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _emergencyService.deleteEmergencyContact(contact.id);
                Navigator.pop(context);
                _loadContacts();

                ErrorWidgets.snackBarSuccess(
                  context: context,
                  message: 'Contact deleted successfully!',
                );
              } catch (e) {
                ErrorWidgets.snackBarError(
                  context: context,
                  message: 'Failed to delete contact: ${e.toString()}',
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _callContact(EmergencyContact contact) {
    // This would integrate with the phone calling functionality
    ErrorWidgets.snackBarSuccess(
      context: context,
      message: 'Calling ${contact.name}...',
    );
  }
}
