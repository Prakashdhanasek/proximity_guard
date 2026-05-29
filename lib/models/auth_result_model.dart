enum AuthMethod {
  face,
  pin,
  rfid,
  mobileApproval,
}

enum AuthStatus {
  idle,
  inProgress,
  success,
  failed,
  awaitingApproval,
}

class AuthResultModel {
  final AuthMethod method;
  final AuthStatus status;
  final String driverId;
  final DateTime timestamp;
  final String message;

  AuthResultModel({
    required this.method,
    required this.status,
    this.driverId = '',
    DateTime? timestamp,
    this.message = '',
  }) : timestamp = timestamp ?? DateTime.now();
}
