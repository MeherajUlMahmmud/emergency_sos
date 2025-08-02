import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../../models/emergency_contact.dart';
import '../../models/emergency_history.dart';
import '../../models/emergency_message.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Logger _logger;

  EmergencyRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required Logger logger,
  })  : _firestore = firestore,
        _auth = auth,
        _logger = logger;

  @override
  Future<Either<Failure, List<EmergencyContact>>> getEmergencyContacts() async {
    try {
      _logger.i('Getting emergency contacts');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      final contacts = snapshot.docs
          .map((doc) => EmergencyContact.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .where((contact) => contact.isActive)
          .toList();

      _logger.i('Retrieved ${contacts.length} emergency contacts');
      return Right(contacts);
    } catch (e) {
      _logger.e('Error getting emergency contacts: $e');
      return Left(ServerFailure('Failed to load emergency contacts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addEmergencyContact(EmergencyContact contact) async {
    try {
      _logger.i('Adding emergency contact: ${contact.name}');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .add(contact.toMap());

      _logger.i('Successfully added emergency contact');
      return const Right(null);
    } catch (e) {
      _logger.e('Error adding emergency contact: $e');
      return Left(ServerFailure('Failed to add emergency contact: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmergencyContact(EmergencyContact contact) async {
    try {
      _logger.i('Updating emergency contact: ${contact.name}');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contact.id)
          .update(contact.toMap());

      _logger.i('Successfully updated emergency contact');
      return const Right(null);
    } catch (e) {
      _logger.e('Error updating emergency contact: $e');
      return Left(ServerFailure('Failed to update emergency contact: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEmergencyContact(String contactId) async {
    try {
      _logger.i('Deleting emergency contact: $contactId');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();

      _logger.i('Successfully deleted emergency contact');
      return const Right(null);
    } catch (e) {
      _logger.e('Error deleting emergency contact: $e');
      return Left(ServerFailure('Failed to delete emergency contact: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EmergencyHistory>>> getEmergencyHistory() async {
    try {
      _logger.i('Getting emergency history');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .orderBy('activatedAt', descending: true)
          .limit(50)
          .get();

      final history = snapshot.docs
          .map((doc) => EmergencyHistory.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      _logger.i('Retrieved ${history.length} emergency history records');
      return Right(history);
    } catch (e) {
      _logger.e('Error getting emergency history: $e');
      return Left(ServerFailure('Failed to load emergency history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addEmergencyHistory(EmergencyHistory history) async {
    try {
      _logger.i('Adding emergency history: ${history.type}');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .add(history.toMap());

      _logger.i('Successfully added emergency history');
      return const Right(null);
    } catch (e) {
      _logger.e('Error adding emergency history: $e');
      return Left(ServerFailure('Failed to add emergency history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateEmergencyHistory(EmergencyHistory history) async {
    try {
      _logger.i('Updating emergency history: ${history.id}');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_history')
          .doc(history.id)
          .update(history.toMap());

      _logger.i('Successfully updated emergency history');
      return const Right(null);
    } catch (e) {
      _logger.e('Error updating emergency history: $e');
      return Left(ServerFailure('Failed to update emergency history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resolveEmergency(String emergencyId) async {
    try {
      _logger.i('Resolving emergency: $emergencyId');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

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
        _logger.i('Successfully resolved emergency');
        return const Right(null);
      } else {
        return const Left(ServerFailure('Emergency not found'));
      }
    } catch (e) {
      _logger.e('Error resolving emergency: $e');
      return Left(ServerFailure('Failed to resolve emergency: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EmergencyMessage>>> getEmergencyMessages() async {
    try {
      _logger.i('Getting emergency messages');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      final prefs = await SharedPreferences.getInstance();
      final customMessagesJson = prefs.getString('custom_emergency_messages') ?? '[]';
      final customMessages = (jsonDecode(customMessagesJson) as List)
          .map((json) => EmergencyMessage.fromMap(json))
          .toList();

      final messages = [...EmergencyMessage.getDefaultMessages(), ...customMessages];
      _logger.i('Retrieved ${messages.length} emergency messages');
      return Right(messages);
    } catch (e) {
      _logger.e('Error getting emergency messages: $e');
      return Left(CacheFailure('Failed to load emergency messages: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomMessage(EmergencyMessage message) async {
    try {
      _logger.i('Saving custom emergency message');
      
      final prefs = await SharedPreferences.getInstance();
      final customMessagesJson = prefs.getString('custom_emergency_messages') ?? '[]';
      final customMessages = (jsonDecode(customMessagesJson) as List)
          .map((json) => EmergencyMessage.fromMap(json))
          .toList();

      customMessages.add(message);

      await prefs.setString(
        'custom_emergency_messages',
        jsonEncode(customMessages.map((m) => m.toMap()).toList()),
      );

      _logger.i('Successfully saved custom emergency message');
      return const Right(null);
    } catch (e) {
      _logger.e('Error saving custom emergency message: $e');
      return Left(CacheFailure('Failed to save custom message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> activateEmergency({
    required String type,
    String? description,
    String? notes,
  }) async {
    try {
      _logger.i('Activating emergency: $type');
      
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthenticationFailure('User not authenticated'));
      }

      // Get current location
      final locationResult = await _getCurrentLocation();
      if (locationResult.isLeft()) {
        return locationResult;
      }
      final position = locationResult.fold((l) => null, (r) => r)!;

      // Get emergency contacts
      final contactsResult = await getEmergencyContacts();
      if (contactsResult.isLeft()) {
        return contactsResult;
      }
      final contacts = contactsResult.fold((l) => <EmergencyContact>[], (r) => r);

      // Create emergency history
      final history = EmergencyHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: EmergencyType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
          orElse: () => EmergencyType.other,
        ),
        status: EmergencyStatus.active,
        activatedAt: DateTime.now(),
        location: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        latitude: position.latitude,
        longitude: position.longitude,
        contactedNumbers: [],
        notes: notes,
        description: description,
      );

      // Save to database
      await addEmergencyHistory(history);

      // Contact emergency services and contacts
      await _contactEmergencyServices(type, position);
      await _contactEmergencyContacts(contacts, type, position);

      _logger.i('Successfully activated emergency');
      return const Right(null);
    } catch (e) {
      _logger.e('Error activating emergency: $e');
      return Left(ServerFailure('Failed to activate emergency: $e'));
    }
  }

  Future<Either<Failure, Position>> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const Left(LocationFailure('Location services are disabled'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const Left(PermissionFailure('Location permissions are denied'));
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const Left(PermissionFailure('Location permissions are permanently denied'));
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Right(position);
    } catch (e) {
      return Left(LocationFailure('Failed to get location: $e'));
    }
  }

  Future<void> _contactEmergencyServices(String type, Position position) async {
    try {
      String emergencyNumber = '911'; // US emergency number
      final url = 'tel:$emergencyNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      _logger.e('Failed to contact emergency services: $e');
    }
  }

  Future<void> _contactEmergencyContacts(
    List<EmergencyContact> contacts,
    String type,
    Position position,
  ) async {
    try {
      final message = EmergencyMessage.getMessageForType(
        EmergencyType.values.firstWhere(
          (e) => e.toString().split('.').last == type,
          orElse: () => EmergencyType.other,
        ),
      );
      final formattedMessage = message.formatMessage(
        location: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
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
      _logger.e('Failed to contact emergency contacts: $e');
    }
  }

  Future<void> _sendEmergencyMessage(
    EmergencyContact contact,
    String message,
  ) async {
    try {
      // Send SMS
      final smsUrl = 'sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}';
      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      }

      // Make phone call
      final callUrl = 'tel:${contact.phoneNumber}';
      if (await canLaunchUrl(Uri.parse(callUrl))) {
        await launchUrl(Uri.parse(callUrl));
      }
    } catch (e) {
      _logger.e('Failed to send emergency message to ${contact.name}: $e');
    }
  }
} 