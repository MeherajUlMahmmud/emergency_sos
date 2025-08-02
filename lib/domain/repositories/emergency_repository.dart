import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../models/emergency_contact.dart';
import '../../models/emergency_history.dart';
import '../../models/emergency_message.dart';

abstract class EmergencyRepository {
  // Emergency Contacts
  Future<Either<Failure, List<EmergencyContact>>> getEmergencyContacts();
  Future<Either<Failure, void>> addEmergencyContact(EmergencyContact contact);
  Future<Either<Failure, void>> updateEmergencyContact(EmergencyContact contact);
  Future<Either<Failure, void>> deleteEmergencyContact(String contactId);

  // Emergency History
  Future<Either<Failure, List<EmergencyHistory>>> getEmergencyHistory();
  Future<Either<Failure, void>> addEmergencyHistory(EmergencyHistory history);
  Future<Either<Failure, void>> updateEmergencyHistory(EmergencyHistory history);
  Future<Either<Failure, void>> resolveEmergency(String emergencyId);

  // Emergency Messages
  Future<Either<Failure, List<EmergencyMessage>>> getEmergencyMessages();
  Future<Either<Failure, void>> saveCustomMessage(EmergencyMessage message);

  // Emergency Activation
  Future<Either<Failure, void>> activateEmergency({
    required String type,
    String? description,
    String? notes,
  });
} 