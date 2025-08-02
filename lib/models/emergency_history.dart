import 'package:flutter/material.dart';

enum EmergencyType {
  medical,
  accident,
  fire,
  crime,
  naturalDisaster,
  other,
}

enum EmergencyStatus {
  active,
  resolved,
  cancelled,
}

class EmergencyHistory {
  final String id;
  final EmergencyType type;
  final EmergencyStatus status;
  final DateTime activatedAt;
  final DateTime? resolvedAt;
  final String? location;
  final double? latitude;
  final double? longitude;
  final List<String> contactedNumbers;
  final String? notes;
  final String? description;

  EmergencyHistory({
    required this.id,
    required this.type,
    required this.status,
    required this.activatedAt,
    this.resolvedAt,
    this.location,
    this.latitude,
    this.longitude,
    required this.contactedNumbers,
    this.notes,
    this.description,
  });

  factory EmergencyHistory.fromMap(Map<String, dynamic> map) {
    return EmergencyHistory(
      id: map['id'] ?? '',
      type: EmergencyType.values.firstWhere(
        (e) => e.toString() == 'EmergencyType.${map['type']}',
        orElse: () => EmergencyType.other,
      ),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.toString() == 'EmergencyStatus.${map['status']}',
        orElse: () => EmergencyStatus.active,
      ),
      activatedAt: DateTime.parse(map['activatedAt']),
      resolvedAt:
          map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
      location: map['location'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      contactedNumbers: List<String>.from(map['contactedNumbers'] ?? []),
      notes: map['notes'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'activatedAt': activatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'contactedNumbers': contactedNumbers,
      'notes': notes,
      'description': description,
    };
  }

  EmergencyHistory copyWith({
    String? id,
    EmergencyType? type,
    EmergencyStatus? status,
    DateTime? activatedAt,
    DateTime? resolvedAt,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? contactedNumbers,
    String? notes,
    String? description,
  }) {
    return EmergencyHistory(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      activatedAt: activatedAt ?? this.activatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactedNumbers: contactedNumbers ?? this.contactedNumbers,
      notes: notes ?? this.notes,
      description: description ?? this.description,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case EmergencyType.medical:
        return 'Medical Emergency';
      case EmergencyType.accident:
        return 'Accident';
      case EmergencyType.fire:
        return 'Fire Emergency';
      case EmergencyType.crime:
        return 'Crime/Assault';
      case EmergencyType.naturalDisaster:
        return 'Natural Disaster';
      case EmergencyType.other:
        return 'Other Emergency';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EmergencyStatus.active:
        return 'Active';
      case EmergencyStatus.resolved:
        return 'Resolved';
      case EmergencyStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case EmergencyStatus.active:
        return Colors.red;
      case EmergencyStatus.resolved:
        return Colors.green;
      case EmergencyStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
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

  Duration get duration {
    final endTime = resolvedAt ?? DateTime.now();
    return endTime.difference(activatedAt);
  }

  String get durationText {
    final duration = this.duration;
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else if (duration.inDays < 1) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    }
  }
}
