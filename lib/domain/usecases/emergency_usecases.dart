import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../models/emergency_contact.dart';
import '../../models/emergency_history.dart';
import '../../models/emergency_message.dart';
import '../repositories/emergency_repository.dart';

// Emergency Contact Use Cases
class GetEmergencyContacts extends UseCase<List<EmergencyContact>, NoParams> {
  final EmergencyRepository repository;

  GetEmergencyContacts(this.repository);

  @override
  Future<Either<Failure, List<EmergencyContact>>> call(NoParams params) async {
    return await repository.getEmergencyContacts();
  }
}

class AddEmergencyContact extends UseCase<void, EmergencyContact> {
  final EmergencyRepository repository;

  AddEmergencyContact(this.repository);

  @override
  Future<Either<Failure, void>> call(EmergencyContact contact) async {
    return await repository.addEmergencyContact(contact);
  }
}

class UpdateEmergencyContact extends UseCase<void, EmergencyContact> {
  final EmergencyRepository repository;

  UpdateEmergencyContact(this.repository);

  @override
  Future<Either<Failure, void>> call(EmergencyContact contact) async {
    return await repository.updateEmergencyContact(contact);
  }
}

class DeleteEmergencyContact extends UseCase<void, String> {
  final EmergencyRepository repository;

  DeleteEmergencyContact(this.repository);

  @override
  Future<Either<Failure, void>> call(String contactId) async {
    return await repository.deleteEmergencyContact(contactId);
  }
}

// Emergency History Use Cases
class GetEmergencyHistory extends UseCase<List<EmergencyHistory>, NoParams> {
  final EmergencyRepository repository;

  GetEmergencyHistory(this.repository);

  @override
  Future<Either<Failure, List<EmergencyHistory>>> call(NoParams params) async {
    return await repository.getEmergencyHistory();
  }
}

class AddEmergencyHistory extends UseCase<void, EmergencyHistory> {
  final EmergencyRepository repository;

  AddEmergencyHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(EmergencyHistory history) async {
    return await repository.addEmergencyHistory(history);
  }
}

class UpdateEmergencyHistory extends UseCase<void, EmergencyHistory> {
  final EmergencyRepository repository;

  UpdateEmergencyHistory(this.repository);

  @override
  Future<Either<Failure, void>> call(EmergencyHistory history) async {
    return await repository.updateEmergencyHistory(history);
  }
}

class ResolveEmergency extends UseCase<void, String> {
  final EmergencyRepository repository;

  ResolveEmergency(this.repository);

  @override
  Future<Either<Failure, void>> call(String emergencyId) async {
    return await repository.resolveEmergency(emergencyId);
  }
}

// Emergency Messages Use Cases
class GetEmergencyMessages extends UseCase<List<EmergencyMessage>, NoParams> {
  final EmergencyRepository repository;

  GetEmergencyMessages(this.repository);

  @override
  Future<Either<Failure, List<EmergencyMessage>>> call(NoParams params) async {
    return await repository.getEmergencyMessages();
  }
}

class SaveCustomMessage extends UseCase<void, EmergencyMessage> {
  final EmergencyRepository repository;

  SaveCustomMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(EmergencyMessage message) async {
    return await repository.saveCustomMessage(message);
  }
}

// Emergency Activation Use Cases
class ActivateEmergencyParams extends Equatable {
  final String type;
  final String? description;
  final String? notes;

  const ActivateEmergencyParams({
    required this.type,
    this.description,
    this.notes,
  });

  @override
  List<Object?> get props => [type, description, notes];
}

class ActivateEmergency extends UseCase<void, ActivateEmergencyParams> {
  final EmergencyRepository repository;

  ActivateEmergency(this.repository);

  @override
  Future<Either<Failure, void>> call(ActivateEmergencyParams params) async {
    return await repository.activateEmergency(
      type: params.type,
      description: params.description,
      notes: params.notes,
    );
  }
} 