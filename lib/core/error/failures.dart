import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure(String message, [String? code]) : super(message, code);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, [String? code]) : super(message, code);
}

class CacheFailure extends Failure {
  const CacheFailure(String message, [String? code]) : super(message, code);
}

class LocationFailure extends Failure {
  const LocationFailure(String message, [String? code]) : super(message, code);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message, [String? code]) : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, [String? code]) : super(message, code);
}

class PermissionFailure extends Failure {
  const PermissionFailure(String message, [String? code]) : super(message, code);
} 