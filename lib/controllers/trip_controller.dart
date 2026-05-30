import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/trip_data_model.dart';
import '../models/trip_alert_model.dart';
import '../models/trip_summary_model.dart';

enum DrivingMode { normal, minimal }

class TripController extends ChangeNotifier {
  TripDataModel _tripData = const TripDataModel();
  final List<TripAlertModel> _alerts = [];
  DrivingMode _drivingMode = DrivingMode.normal;
  bool _isTripActive = false;
  Timer? _simulationTimer;
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;
  final _random = Random();

  // Post-trip data
  TripSummaryModel? _lastTripSummary;
  final List<DrivingTrend> _drivingTrends = [];
  DateTime? _tripStartTime;
  final List<double> _speedSamples = [];
  int _tooCloseCount = 0;
  int _overSpeedCount = 0;
  int _totalSamples = 0;

  TripDataModel get tripData => _tripData;
  List<TripAlertModel> get alerts => List.unmodifiable(_alerts);
  List<TripAlertModel> get activeAlerts => _alerts.where((a) => !a.isDismissed).toList();
  DrivingMode get drivingMode => _drivingMode;
  bool get isTripActive => _isTripActive;
  TripSummaryModel? get lastTripSummary => _lastTripSummary;
  List<DrivingTrend> get drivingTrends => List.unmodifiable(_drivingTrends);

  void startTrip() {
    _isTripActive = true;
    _elapsed = Duration.zero;
    _tripStartTime = DateTime.now();
    _speedSamples.clear();
    _tooCloseCount = 0;
    _overSpeedCount = 0;
    _totalSamples = 0;
    _tripData = const TripDataModel(currentSpeed: 0, routeProgress: 0);
    _alerts.clear();
    _lastTripSummary = null;
    notifyListeners();
    _startSimulation();
  }

  void endTrip() {
    _isTripActive = false;
    _simulationTimer?.cancel();
    _durationTimer?.cancel();
    _generateTripSummary();
    notifyListeners();
  }

  void toggleDrivingMode() {
    _drivingMode = _drivingMode == DrivingMode.normal
        ? DrivingMode.minimal
        : DrivingMode.normal;
    notifyListeners();
  }

  void dismissAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  void _startSimulation() {
    // Update trip duration every second
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsed += const Duration(seconds: 1);
      _tripData = _tripData.copyWith(tripDuration: _elapsed);
      notifyListeners();
    });

    // Simulate driving data every 2 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _simulateDrivingData();
    });
  }

  void _simulateDrivingData() {
    // Simulate speed fluctuation (40-80 km/h)
    final speed = 40.0 + _random.nextDouble() * 40;
    // Simulate following distance (10-80m)
    final distance = 10.0 + _random.nextDouble() * 70;
    // Simulate route progress
    final progress = (_tripData.routeProgress + 0.005).clamp(0.0, 1.0);
    final km = _tripData.distanceCovered + (speed / 3600) * 2;

    _tripData = _tripData.copyWith(
      currentSpeed: speed,
      followingDistance: distance,
      routeProgress: progress,
      distanceCovered: km,
    );

    // Track samples for post-trip scoring
    _speedSamples.add(speed);
    _totalSamples++;
    if (distance < _tripData.safeFollowingDistance) _tooCloseCount++;
    if (speed > _tripData.speedLimit) _overSpeedCount++;

    // Random alerts (5% chance per tick)
    if (_random.nextDouble() < 0.05) {
      _generateRandomAlert();
    }

    // Distance-based alert
    if (distance < _tripData.safeFollowingDistance && _random.nextDouble() < 0.4) {
      _addAlert(
        type: AlertType.forwardDistance,
        severity: distance < 15 ? AlertSeverity.critical : AlertSeverity.high,
        title: 'Too Close!',
        message: 'Maintain safe following distance (${distance.toInt()}m)',
      );
    }

    // Speed alert
    if (speed > _tripData.speedLimit && _random.nextDouble() < 0.3) {
      _addAlert(
        type: AlertType.speedLimit,
        severity: AlertSeverity.medium,
        title: 'Speed Limit',
        message: 'Current: ${speed.toInt()} km/h — Limit: ${_tripData.speedLimit.toInt()} km/h',
      );
    }

    notifyListeners();
  }

  void _generateRandomAlert() {
    final types = [AlertType.drowsiness, AlertType.distraction, AlertType.geofenceBreach];
    final type = types[_random.nextInt(types.length)];

    switch (type) {
      case AlertType.drowsiness:
        _addAlert(
          type: type,
          severity: AlertSeverity.critical,
          title: 'Drowsiness Detected',
          message: 'Eye closure detected. Consider taking a break.',
        );
      case AlertType.distraction:
        _addAlert(
          type: type,
          severity: AlertSeverity.high,
          title: 'Distraction Alert',
          message: 'Phone usage detected. Keep eyes on road.',
        );
      case AlertType.geofenceBreach:
        _addAlert(
          type: type,
          severity: AlertSeverity.medium,
          title: 'Geofence Warning',
          message: 'Approaching boundary of permitted zone.',
        );
      default:
        break;
    }
  }

  void _addAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
  }) {
    // Don't stack same type alerts within 10 seconds
    final recent = _alerts.where((a) => a.type == type && !a.isDismissed).toList();
    if (recent.isNotEmpty) return;

    _alerts.insert(
      0,
      TripAlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        severity: severity,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void _generateTripSummary() {
    final now = DateTime.now();
    final startTime = _tripStartTime ?? now.subtract(_elapsed);

    // Calculate average and max speed
    final avgSpeed = _speedSamples.isNotEmpty
        ? _speedSamples.reduce((a, b) => a + b) / _speedSamples.length
        : 0.0;
    final maxSpeed = _speedSamples.isNotEmpty
        ? _speedSamples.reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Safety scores (0-100)
    final followingScore = _totalSamples > 0
        ? ((1 - (_tooCloseCount / _totalSamples)) * 100).round().clamp(0, 100)
        : 100;
    final speedScore = _totalSamples > 0
        ? ((1 - (_overSpeedCount / _totalSamples)) * 100).round().clamp(0, 100)
        : 100;

    // Alert response: fewer critical/high alerts = better
    final severeAlerts = _alerts.where((a) =>
        a.severity == AlertSeverity.critical || a.severity == AlertSeverity.high).length;
    final alertScore = (100 - (severeAlerts * 8)).clamp(0, 100);

    // Attentiveness: penalize drowsiness/distraction alerts
    final attentionAlerts = _alerts.where((a) =>
        a.type == AlertType.drowsiness || a.type == AlertType.distraction).length;
    final attentivenessScore = (100 - (attentionAlerts * 12)).clamp(0, 100);

    final breakdown = SafetyBreakdown(
      followingDistanceScore: followingScore,
      speedComplianceScore: speedScore,
      alertResponseScore: alertScore,
      attentivenessScore: attentivenessScore,
    );

    final overallScore = (
      followingScore * 0.30 +
      speedScore * 0.30 +
      alertScore * 0.20 +
      attentivenessScore * 0.20
    ).round().clamp(0, 100);

    // Generate incidents from alerts
    final incidents = _alerts.map((alert) {
      final alertOffset = alert.timestamp.difference(startTime);
      return TripIncident(
        id: alert.id,
        alert: alert,
        timestampInTrip: alertOffset.isNegative ? Duration.zero : alertOffset,
        hasVideo: alert.type == AlertType.drowsiness ||
            alert.type == AlertType.distraction,
      );
    }).toList();

    _lastTripSummary = TripSummaryModel(
      id: now.millisecondsSinceEpoch.toString(),
      startTime: startTime,
      endTime: now,
      duration: _elapsed,
      distanceKm: _tripData.distanceCovered,
      routeName: _tripData.routeName,
      averageSpeed: avgSpeed,
      maxSpeed: maxSpeed,
      speedLimit: _tripData.speedLimit,
      safetyScore: overallScore,
      alerts: List.from(_alerts),
      incidents: incidents,
      safetyBreakdown: breakdown,
    );

    // Add to driving trends
    _drivingTrends.add(DrivingTrend(
      date: now,
      safetyScore: overallScore,
      distanceKm: _tripData.distanceCovered,
      alertCount: _alerts.length,
    ));
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }
}
