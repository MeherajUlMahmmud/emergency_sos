import 'package:flutter/material.dart';

enum ContactCategory {
  family,
  friend,
  police,
  medical,
  fire,
  ambulance,
  custom,
}

enum ContactPriority {
  high,
  medium,
  low,
}

class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final ContactCategory category;
  final ContactPriority priority;
  final String? relationship;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastContacted;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.category,
    required this.priority,
    this.relationship,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.lastContacted,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      category: ContactCategory.values.firstWhere(
        (e) => e.toString() == 'ContactCategory.${map['category']}',
        orElse: () => ContactCategory.family,
      ),
      priority: ContactPriority.values.firstWhere(
        (e) => e.toString() == 'ContactPriority.${map['priority']}',
        orElse: () => ContactPriority.medium,
      ),
      relationship: map['relationship'],
      notes: map['notes'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      lastContacted: map['lastContacted'] != null
          ? DateTime.parse(map['lastContacted'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'relationship': relationship,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastContacted': lastContacted?.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    ContactCategory? category,
    ContactPriority? priority,
    String? relationship,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastContacted,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastContacted: lastContacted ?? this.lastContacted,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case ContactCategory.family:
        return 'Family';
      case ContactCategory.friend:
        return 'Friend';
      case ContactCategory.police:
        return 'Police';
      case ContactCategory.medical:
        return 'Medical';
      case ContactCategory.fire:
        return 'Fire Department';
      case ContactCategory.ambulance:
        return 'Ambulance';
      case ContactCategory.custom:
        return 'Custom';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ContactPriority.high:
        return 'High';
      case ContactPriority.medium:
        return 'Medium';
      case ContactPriority.low:
        return 'Low';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case ContactPriority.high:
        return Colors.red;
      case ContactPriority.medium:
        return Colors.orange;
      case ContactPriority.low:
        return Colors.green;
    }
  }

  IconData get categoryIcon {
    switch (category) {
      case ContactCategory.family:
        return Icons.family_restroom;
      case ContactCategory.friend:
        return Icons.people;
      case ContactCategory.police:
        return Icons.local_police;
      case ContactCategory.medical:
        return Icons.medical_services;
      case ContactCategory.fire:
        return Icons.local_fire_department;
      case ContactCategory.ambulance:
        return Icons.emergency;
      case ContactCategory.custom:
        return Icons.person;
    }
  }
} 