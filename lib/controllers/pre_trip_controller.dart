import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PreTripStep {
  authentication,
  vehicleAssignment,
  checklist,
  ready,
}

class PreTripController extends ChangeNotifier {
  // Stores the timestamp (ms since epoch) of the last completed full setup
  // (vehicle + inspection). Used to decide when the weekly full flow is due.
  static const _lastSetupKey = 'pre_trip_last_setup_ms';

  // How often the full (vehicle + inspection) flow must be repeated.
  static const Duration _fullFlowEvery = Duration(days: 7);

  PreTripStep _currentStep = PreTripStep.authentication;
  bool _isVehicleStartAuthorized = false;

  // True => show the full 4-step flow. Defaults to true (safe fallback: first
  // launch / prefs not read yet => full flow).
  bool _needsFullSetup = true;

  PreTripController() {
    _loadSetupState();
  }

  PreTripStep get currentStep => _currentStep;
  bool get isVehicleStartAuthorized => _isVehicleStartAuthorized;

  /// True when the full vehicle + inspection flow is due (first launch, or a
  /// week has passed since it was last completed).
  bool get isFirstSetup => _needsFullSetup;

  /// First launch / weekly refresh -> all 4 steps.
  /// Within the week -> identity + start only.
  List<PreTripStep> get activeSteps => _needsFullSetup
      ? PreTripStep.values
      : const [PreTripStep.authentication, PreTripStep.ready];

  Future<void> _loadSetupState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastSetupKey);

    if (lastMs == null) {
      // Never completed a full setup -> first time -> full flow.
      _needsFullSetup = true;
    } else {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      final elapsed = DateTime.now().difference(last);
      // A week (or more) has passed -> full flow is due again.
      _needsFullSetup = elapsed >= _fullFlowEvery;
    }
    notifyListeners();
  }

  void onAuthSuccess() {
    if (_needsFullSetup) {
      // First time / weekly refresh: collect vehicle + inspection.
      _currentStep = PreTripStep.vehicleAssignment;
    } else {
      // Within the week: vehicle & inspection still valid -> go to start.
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
    // Stamp "now" as the last full setup so the next full flow is due in a week.
    _persistSetupNow();
    notifyListeners();
  }

  Future<void> _persistSetupNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSetupKey, DateTime.now().millisecondsSinceEpoch);
  }

  void reset() {
    _currentStep = PreTripStep.authentication;
    _isVehicleStartAuthorized = false;
    notifyListeners();
  }

  /// Developer/testing helper: forget the saved setup so the next launch shows
  /// the full vehicle + inspection flow again. (Not used by the normal flow.)
  Future<void> forceFullSetupNextTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSetupKey);
    _needsFullSetup = true;
    notifyListeners();
  }
}