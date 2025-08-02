import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_history.dart';
import '../models/emergency_message.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Emergency Contacts Management
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyContact.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .where((contact) => contact.isActive)
          .toList();
    } catch (e) {
      throw Exception('Failed to load emergency contacts: $e');
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .add(contact.toMap());
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contact.id)
          .update(contact.toMap());
    } catch (e) {
      throw Exception('Failed to update emergency contact: $e');
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete emergency contact: $e');
    }
  }

  // Emergency History Management
  Future<List<EmergencyHistory>> getEmergencyHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .orderBy('activatedAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => EmergencyHistory.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to load emergency history: $e');
    }
  }

  Future<void> addEmergencyHistory(EmergencyHistory history) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .add(history.toMap());
    } catch (e) {
      throw Exception('Failed to add emergency history: $e');
    }
  }

  Future<void> updateEmergencyHistory(EmergencyHistory history) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .doc(history.id)
          .update(history.toMap());
    } catch (e) {
      throw Exception('Failed to update emergency history: $e');
    }
  }

  // Location Services
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  Future<String> getLocationAddress(double latitude, double longitude) async {
    try {
      // For now, return coordinates as location
      // In a real app, you would use a geocoding service
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // Emergency Activation
  Future<void> activateEmergency({
    required EmergencyType type,
    String? description,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current location
      final position = await getCurrentLocation();
      final locationAddress = await getLocationAddress(
        position.latitude,
        position.longitude,
      );

      // Get emergency contacts
      final contacts = await getEmergencyContacts();
      final contactedNumbers = <String>[];

      // Create emergency history
      final history = EmergencyHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        status: EmergencyStatus.active,
        activatedAt: DateTime.now(),
        location: locationAddress,
        latitude: position.latitude,
        longitude: position.longitude,
        contactedNumbers: contactedNumbers,
        notes: notes,
        description: description,
      );

      // Save to database
      await addEmergencyHistory(history);

      // Contact emergency services and contacts
      await _contactEmergencyServices(type, position, locationAddress);
      await _contactEmergencyContacts(
          contacts, type, position, locationAddress);

      // Update history with contacted numbers
      final updatedHistory = history.copyWith(
        contactedNumbers: contactedNumbers,
      );
      await updateEmergencyHistory(updatedHistory);
    } catch (e) {
      throw Exception('Failed to activate emergency: $e');
    }
  }

  Future<void> _contactEmergencyServices(
    EmergencyType type,
    Position position,
    String locationAddress,
  ) async {
    try {
      String emergencyNumber;
      switch (type) {
        case EmergencyType.medical:
        case EmergencyType.accident:
          emergencyNumber = '911'; // US emergency number
          break;
        case EmergencyType.fire:
          emergencyNumber = '911';
          break;
        case EmergencyType.crime:
          emergencyNumber = '911';
          break;
        default:
          emergencyNumber = '911';
      }

      final url = 'tel:$emergencyNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Failed to contact emergency services: $e');
    }
  }

  Future<void> _contactEmergencyContacts(
    List<EmergencyContact> contacts,
    EmergencyType type,
    Position position,
    String locationAddress,
  ) async {
    try {
      final message = EmergencyMessage.getMessageForType(type);
      final formattedMessage = message.formatMessage(
        location: locationAddress,
        latitude: position.latitude,
        longitude: position.longitude,
        userName: _auth.currentUser?.displayName ?? 'User',
      );

      // Contact high priority contacts first
      final highPriorityContacts = contacts
          .where((contact) => contact.priority == ContactPriority.high)
          .toList();

      for (final contact in highPriorityContacts) {
        await _sendEmergencyMessage(contact, formattedMessage);
      }

      // Then contact medium priority contacts
      final mediumPriorityContacts = contacts
          .where((contact) => contact.priority == ContactPriority.medium)
          .toList();

      for (final contact in mediumPriorityContacts) {
        await _sendEmergencyMessage(contact, formattedMessage);
      }
    } catch (e) {
      print('Failed to contact emergency contacts: $e');
    }
  }

  Future<void> _sendEmergencyMessage(
    EmergencyContact contact,
    String message,
  ) async {
    try {
      // Send SMS
      final smsUrl =
          'sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      }

      // Make phone call
      final callUrl = 'tel:${contact.phoneNumber}';
      if (await canLaunchUrl(Uri.parse(callUrl))) {
        await launchUrl(Uri.parse(callUrl));
      }
    } catch (e) {
      print('Failed to send emergency message to ${contact.name}: $e');
    }
  }

  // Emergency Message Templates
  Future<List<EmergencyMessage>> getEmergencyMessages() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final prefs = await SharedPreferences.getInstance();
      final customMessagesJson =
          prefs.getString('custom_emergency_messages') ?? '[]';
      final customMessages = (jsonDecode(customMessagesJson) as List)
          .map((json) => EmergencyMessage.fromMap(json))
          .toList();

      return [...EmergencyMessage.getDefaultMessages(), ...customMessages];
    } catch (e) {
      return EmergencyMessage.getDefaultMessages();
    }
  }

  Future<void> saveCustomMessage(EmergencyMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customMessagesJson =
          prefs.getString('custom_emergency_messages') ?? '[]';
      final customMessages = (jsonDecode(customMessagesJson) as List)
          .map((json) => EmergencyMessage.fromMap(json))
          .toList();

      customMessages.add(message);

      await prefs.setString(
        'custom_emergency_messages',
        jsonEncode(customMessages.map((m) => m.toMap()).toList()),
      );
    } catch (e) {
      throw Exception('Failed to save custom message: $e');
    }
  }

  // Resolve Emergency
  Future<void> resolveEmergency(String emergencyId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final history = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .doc(emergencyId)
          .get();

      if (history.exists) {
        final emergencyHistory = EmergencyHistory.fromMap({
          'id': history.id,
          ...history.data()!,
        });

        final updatedHistory = emergencyHistory.copyWith(
          status: EmergencyStatus.resolved,
          resolvedAt: DateTime.now(),
        );

        await updateEmergencyHistory(updatedHistory);
      }
    } catch (e) {
      throw Exception('Failed to resolve emergency: $e');
    }
  }
}
