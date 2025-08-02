import 'package:flutter/foundation.dart';
import '../core/error/failures.dart';
import '../core/usecases/usecase.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_history.dart';
import '../models/emergency_message.dart';
import '../domain/usecases/emergency_usecases.dart';

class EmergencyProvider extends ChangeNotifier {
  final GetEmergencyContacts getEmergencyContacts;
  final AddEmergencyContact addEmergencyContact;
  final UpdateEmergencyContact updateEmergencyContact;
  final DeleteEmergencyContact deleteEmergencyContact;
  final GetEmergencyHistory getEmergencyHistory;
  final AddEmergencyHistory addEmergencyHistory;
  final UpdateEmergencyHistory updateEmergencyHistory;
  final ResolveEmergency resolveEmergency;
  final GetEmergencyMessages getEmergencyMessages;
  final SaveCustomMessage saveCustomMessage;
  final ActivateEmergency activateEmergency;

  EmergencyProvider({
    required this.getEmergencyContacts,
    required this.addEmergencyContact,
    required this.updateEmergencyContact,
    required this.deleteEmergencyContact,
    required this.getEmergencyHistory,
    required this.addEmergencyHistory,
    required this.updateEmergencyHistory,
    required this.resolveEmergency,
    required this.getEmergencyMessages,
    required this.saveCustomMessage,
    required this.activateEmergency,
  });

  // State
  List<EmergencyContact> _contacts = [];
  List<EmergencyHistory> _history = [];
  List<EmergencyMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EmergencyContact> get contacts => _contacts;
  List<EmergencyHistory> get history => _history;
  List<EmergencyMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Emergency Contacts
  Future<void> loadEmergencyContacts() async {
    _setLoading(true);
    _clearError();

    final result = await getEmergencyContacts(NoParams());
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (contacts) => _setContacts(contacts),
    );

    _setLoading(false);
  }

  Future<void> addContact(EmergencyContact contact) async {
    _setLoading(true);
    _clearError();

    final result = await addEmergencyContact(contact);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyContacts(), // Reload contacts
    );

    _setLoading(false);
  }

  Future<void> updateContact(EmergencyContact contact) async {
    _setLoading(true);
    _clearError();

    final result = await updateEmergencyContact(contact);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyContacts(), // Reload contacts
    );

    _setLoading(false);
  }

  Future<void> deleteContact(String contactId) async {
    _setLoading(true);
    _clearError();

    final result = await deleteEmergencyContact(contactId);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyContacts(), // Reload contacts
    );

    _setLoading(false);
  }

  // Emergency History
  Future<void> loadEmergencyHistory() async {
    _setLoading(true);
    _clearError();

    final result = await getEmergencyHistory(NoParams());
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (history) => _setHistory(history),
    );

    _setLoading(false);
  }

  Future<void> addHistory(EmergencyHistory history) async {
    _setLoading(true);
    _clearError();

    final result = await addEmergencyHistory(history);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyHistory(), // Reload history
    );

    _setLoading(false);
  }

  Future<void> updateHistory(EmergencyHistory history) async {
    _setLoading(true);
    _clearError();

    final result = await updateEmergencyHistory(history);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyHistory(), // Reload history
    );

    _setLoading(false);
  }

  Future<void> resolveEmergencyById(String emergencyId) async {
    _setLoading(true);
    _clearError();

    final result = await resolveEmergency(emergencyId);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyHistory(), // Reload history
    );

    _setLoading(false);
  }

  // Emergency Messages
  Future<void> loadEmergencyMessages() async {
    _setLoading(true);
    _clearError();

    final result = await getEmergencyMessages(NoParams());
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (messages) => _setMessages(messages),
    );

    _setLoading(false);
  }

  Future<void> saveMessage(EmergencyMessage message) async {
    _setLoading(true);
    _clearError();

    final result = await saveCustomMessage(message);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) => loadEmergencyMessages(), // Reload messages
    );

    _setLoading(false);
  }

  // Emergency Activation
  Future<void> activateEmergencySystem({
    required String type,
    String? description,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    final params = ActivateEmergencyParams(
      type: type,
      description: description,
      notes: notes,
    );

    final result = await activateEmergency(params);
    result.fold(
      (failure) => _setError(_mapFailureToMessage(failure)),
      (_) {
        // Emergency activated successfully
        loadEmergencyHistory(); // Reload history
      },
    );

    _setLoading(false);
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setContacts(List<EmergencyContact> contacts) {
    _contacts = contacts;
    notifyListeners();
  }

  void _setHistory(List<EmergencyHistory> history) {
    _history = history;
    notifyListeners();
  }

  void _setMessages(List<EmergencyMessage> messages) {
    _messages = messages;
    notifyListeners();
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return 'Network error: ${failure.message}';
      case CacheFailure:
        return 'Storage error: ${failure.message}';
      case LocationFailure:
        return 'Location error: ${failure.message}';
      case AuthenticationFailure:
        return 'Authentication error: ${failure.message}';
      case ValidationFailure:
        return 'Validation error: ${failure.message}';
      case PermissionFailure:
        return 'Permission error: ${failure.message}';
      default:
        return 'Unexpected error: ${failure.message}';
    }
  }
}
