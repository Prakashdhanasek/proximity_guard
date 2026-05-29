import 'package:flutter/foundation.dart';
import '../models/auth_result_model.dart';
import '../models/driver_model.dart';

class AuthController extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  AuthMethod? _currentMethod;
  String _message = '';
  DriverModel? _authenticatedDriver;
  int _pinAttempts = 0;
  static const int maxPinAttempts = 3;

  // Mock enrolled driver for demo
  final DriverModel _mockDriver = DriverModel(
    id: 'DRV-001',
    name: 'Ravi Kumar',
    licenseNumber: 'TN-38-2024-001234',
    isBiometricEnrolled: true,
    rfidTag: 'RFID-PGD-001',
    pin: '1234',
  );

  AuthStatus get status => _status;
  AuthMethod? get currentMethod => _currentMethod;
  String get message => _message;
  DriverModel? get authenticatedDriver => _authenticatedDriver;
  int get pinAttempts => _pinAttempts;
  int get remainingAttempts => maxPinAttempts - _pinAttempts;

  void selectMethod(AuthMethod method) {
    _currentMethod = method;
    _status = AuthStatus.idle;
    _message = '';
    notifyListeners();
  }

  // Face Authentication (mock)
  Future<void> authenticateWithFace() async {
    _status = AuthStatus.inProgress;
    _currentMethod = AuthMethod.face;
    _message = 'Scanning face...';
    notifyListeners();

    // Simulate face scanning delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate liveness check
    _message = 'Liveness check...';
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));

    // Mock success
    _status = AuthStatus.success;
    _authenticatedDriver = _mockDriver;
    _message = 'Face verified successfully';
    notifyListeners();
  }

  // PIN Authentication
  Future<void> authenticateWithPin(String pin) async {
    _status = AuthStatus.inProgress;
    _currentMethod = AuthMethod.pin;
    _message = 'Verifying PIN...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (pin == _mockDriver.pin) {
      _status = AuthStatus.success;
      _authenticatedDriver = _mockDriver;
      _message = 'PIN verified successfully';
      _pinAttempts = 0;
    } else {
      _pinAttempts++;
      if (_pinAttempts >= maxPinAttempts) {
        _status = AuthStatus.failed;
        _message = 'Too many failed attempts. Account locked.';
      } else {
        _status = AuthStatus.failed;
        _message = 'Invalid PIN. $remainingAttempts attempts remaining.';
      }
    }
    notifyListeners();
  }

  // RFID/NFC Authentication (mock)
  Future<void> authenticateWithRfid() async {
    _status = AuthStatus.inProgress;
    _currentMethod = AuthMethod.rfid;
    _message = 'Waiting for NFC/RFID tap...';
    notifyListeners();

    // Simulate tap detection
    await Future.delayed(const Duration(seconds: 3));

    _status = AuthStatus.success;
    _authenticatedDriver = _mockDriver;
    _message = 'RFID card verified';
    notifyListeners();
  }

  // Mobile Approval (mock)
  Future<void> requestMobileApproval() async {
    _status = AuthStatus.awaitingApproval;
    _currentMethod = AuthMethod.mobileApproval;
    _message = 'Approval request sent to fleet manager...';
    notifyListeners();

    // Simulate manager response
    await Future.delayed(const Duration(seconds: 4));

    _status = AuthStatus.success;
    _authenticatedDriver = _mockDriver;
    _message = 'Manager approved. Access granted.';
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.idle;
    _currentMethod = null;
    _message = '';
    _authenticatedDriver = null;
    _pinAttempts = 0;
    notifyListeners();
  }
}
