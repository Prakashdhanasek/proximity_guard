import 'package:flutter/foundation.dart';

enum PreTripStep {
  authentication,
  vehicleAssignment,
  checklist,
  ready,
}

class PreTripController extends ChangeNotifier {
  PreTripStep _currentStep = PreTripStep.authentication;
  bool _isVehicleStartAuthorized = false;

  PreTripStep get currentStep => _currentStep;
  bool get isVehicleStartAuthorized => _isVehicleStartAuthorized;

  void onAuthSuccess() {
    _currentStep = PreTripStep.vehicleAssignment;
    notifyListeners();
  }

  void onVehicleConfirmed() {
    _currentStep = PreTripStep.checklist;
    notifyListeners();
  }

  void onChecklistCompleted() {
    _currentStep = PreTripStep.ready;
    _isVehicleStartAuthorized = true;
    notifyListeners();
  }

  void reset() {
    _currentStep = PreTripStep.authentication;
    _isVehicleStartAuthorized = false;
    notifyListeners();
  }
}
