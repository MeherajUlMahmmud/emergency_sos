import 'emergency_history.dart';

class EmergencyMessage {
  final String id;
  final String title;
  final String message;
  final EmergencyType emergencyType;
  final bool isDefault;
  final bool isCustom;

  EmergencyMessage({
    required this.id,
    required this.title,
    required this.message,
    required this.emergencyType,
    this.isDefault = false,
    this.isCustom = false,
  });

  factory EmergencyMessage.fromMap(Map<String, dynamic> map) {
    return EmergencyMessage(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      emergencyType: EmergencyType.values.firstWhere(
        (e) => e.toString() == 'EmergencyType.${map['emergencyType']}',
        orElse: () => EmergencyType.other,
      ),
      isDefault: map['isDefault'] ?? false,
      isCustom: map['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'emergencyType': emergencyType.toString().split('.').last,
      'isDefault': isDefault,
      'isCustom': isCustom,
    };
  }

  String formatMessage({
    String? location,
    double? latitude,
    double? longitude,
    String? userName,
  }) {
    String formattedMessage = message;
    
    if (location != null) {
      formattedMessage = formattedMessage.replaceAll('{location}', location);
    }
    
    if (latitude != null && longitude != null) {
      final coordinates = 'https://maps.google.com/?q=$latitude,$longitude';
      formattedMessage = formattedMessage.replaceAll('{coordinates}', coordinates);
    }
    
    if (userName != null) {
      formattedMessage = formattedMessage.replaceAll('{name}', userName);
    }
    
    return formattedMessage;
  }

  static List<EmergencyMessage> getDefaultMessages() {
    return [
      EmergencyMessage(
        id: 'medical_default',
        title: 'Medical Emergency',
        message: 'EMERGENCY: {name} needs immediate medical attention at {location}. Please call emergency services. Location: {coordinates}',
        emergencyType: EmergencyType.medical,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'accident_default',
        title: 'Accident',
        message: 'EMERGENCY: {name} has been in an accident at {location}. Please send help immediately. Location: {coordinates}',
        emergencyType: EmergencyType.accident,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'fire_default',
        title: 'Fire Emergency',
        message: 'EMERGENCY: Fire at {location}. {name} needs immediate evacuation assistance. Location: {coordinates}',
        emergencyType: EmergencyType.fire,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'crime_default',
        title: 'Crime/Assault',
        message: 'EMERGENCY: {name} is in danger at {location}. Please call police immediately. Location: {coordinates}',
        emergencyType: EmergencyType.crime,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'natural_disaster_default',
        title: 'Natural Disaster',
        message: 'EMERGENCY: Natural disaster at {location}. {name} needs immediate assistance. Location: {coordinates}',
        emergencyType: EmergencyType.naturalDisaster,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'general_default',
        title: 'General Emergency',
        message: 'EMERGENCY: {name} needs immediate help at {location}. Please respond urgently. Location: {coordinates}',
        emergencyType: EmergencyType.other,
        isDefault: true,
      ),
      EmergencyMessage(
        id: 'simple_default',
        title: 'Simple SOS',
        message: 'SOS: {name} needs help at {location}. Please call. {coordinates}',
        emergencyType: EmergencyType.other,
        isDefault: true,
      ),
    ];
  }

  static EmergencyMessage getMessageForType(EmergencyType type) {
    final messages = getDefaultMessages();
    return messages.firstWhere(
      (msg) => msg.emergencyType == type,
      orElse: () => messages.last, // Return general emergency message
    );
  }
} 