import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreTripStep {
  authentication,
  vehicleAssignment,
  checklist,
  ready,
}

class PreTripController extends ChangeNotifier {
  // Stored once the first full registration (vehicle + inspection) is done.
  static const _setupDoneKey = 'pre_trip_setup_done';

  PreTripStep _currentStep = PreTripStep.authentication;
  bool _isVehicleStartAuthorized = false;

  // Defaults to `true` (full flow) until prefs are read — the safe fallback.
  bool _isFirstSetup = true;

  PreTripController() {
    _loadSetupState();
  }

  PreTripStep get currentStep => _currentStep;
  bool get isVehicleStartAuthorized => _isVehicleStartAuthorized;
  bool get isFirstSetup => _isFirstSetup;

  /// Steps actually shown for the current mode.
  /// First registration → all 4 steps. Daily → identity + start only.
  List<PreTripStep> get activeSteps => _isFirstSetup
      ? PreTripStep.values
      : const [PreTripStep.authentication, PreTripStep.ready];

  Future<void> _loadSetupState() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstSetup = !(prefs.getBool(_setupDoneKey) ?? false);
    notifyListeners();
  }

  void onAuthSuccess() {
    if (_isFirstSetup) {
      // First registration: collect vehicle + inspection.
      _currentStep = PreTripStep.vehicleAssignment;
    } else {
      // Daily: vehicle & inspection already registered — go straight to start.
      _currentStep = PreTripStep.ready;
      _isVehicleStartAuthorized = true;
    }
    notifyListeners();
  }

  void onVehicleConfirmed() {
    _currentStep = PreTripStep.checklist;
    notifyListeners();
  }

  void onChecklistCompleted() {
    _currentStep = PreTripStep.ready;
    _isVehicleStartAuthorized = true;
    // Mark registration complete for future launches. We persist it but keep
    // the current session in full-flow mode (no mid-session step collapse);
    // daily mode kicks in on the next app launch.
    _persistSetupDone();
    notifyListeners();
  }

  Future<void> _persistSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupDoneKey, true);
  }

  void reset() {
    _currentStep = PreTripStep.authentication;
    _isVehicleStartAuthorized = false;
    notifyListeners();
  }
}