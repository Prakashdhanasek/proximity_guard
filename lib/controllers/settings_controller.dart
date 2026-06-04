import 'dart:math';
import 'package:flutter/material.dart';
import '../models/general_models.dart';
import '../models/trip_summary_model.dart';

class SettingsController extends ChangeNotifier {
  // Theme
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // Language
  String _locale = 'en';
  String get locale => _locale;

  static const supportedLocales = {
    'en': 'English',
    'hi': 'हिन्दी (Hindi)',
    'ar': 'العربية (Arabic)',
    'ta': 'தமிழ் (Tamil)',
    'es': 'Español (Spanish)',
    'fr': 'Français (French)',
    'de': 'Deutsch (German)',
    'ms': 'Bahasa Melayu (Malay)',
    'th': 'ไทย (Thai)',
    'vi': 'Tiếng Việt (Vietnamese)',
  };

  // Notifications
  final List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Trip History
  final List<TripHistoryEntry> _tripHistory = [];
  List<TripHistoryEntry> get tripHistory => List.unmodifiable(_tripHistory);

  // Biometric Templates
  final List<BiometricTemplate> _biometricTemplates = [];
  List<BiometricTemplate> get biometricTemplates => List.unmodifiable(_biometricTemplates);

  // Privacy
  bool _consentGiven = true;
  bool get consentGiven => _consentGiven;

  SettingsController() {
    _generateMockData();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  /// Adds a new notification to the top of the notification center.
  /// Used by the live driver-monitoring (drowsiness / distraction / banned
  /// object) so detections appear alongside other notifications.
  void addNotification({
    required NotificationType type,
    required String title,
    required String message,
  }) {
    _notifications.insert(
      0,
      NotificationModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void addTripToHistory(TripSummaryModel summary) {
    _tripHistory.insert(0, TripHistoryEntry(
      id: summary.id,
      date: summary.endTime,
      routeName: summary.routeName,
      duration: summary.duration,
      distanceKm: summary.distanceKm,
      averageSpeed: summary.averageSpeed,
      safetyScore: summary.safetyScore,
      alertCount: summary.alerts.length,
    ));
    notifyListeners();
  }

  void deleteBiometricTemplate(String id) {
    _biometricTemplates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void toggleConsent(bool value) {
    _consentGiven = value;
    notifyListeners();
  }

  void _generateMockData() {
    final rng = Random(42);
    final now = DateTime.now();

    // Mock notifications
    _notifications.addAll([
      NotificationModel(
        id: '1',
        type: NotificationType.tamperAlert,
        title: 'Tamper Alert',
        message: 'OBD device disconnect detected on vehicle TN-38-AB-1234',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: '2',
        type: NotificationType.managerMessage,
        title: 'Fleet Manager',
        message: 'Route update: Detour on NH-48 near Krishnagiri. Use alternate route via Hosur.',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: '3',
        type: NotificationType.unauthorizedAccess,
        title: 'Unauthorized Attempt',
        message: 'Failed face authentication attempt on vehicle TN-38-AB-5678',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        type: NotificationType.systemUpdate,
        title: 'System Update',
        message: 'Proximity Guard v2.5 available. New drowsiness model improved 15%.',
        timestamp: now.subtract(const Duration(hours: 8)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.tripReminder,
        title: 'Trip Reminder',
        message: 'Scheduled delivery to Hub-B at 10:00 AM tomorrow.',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.safetyWarning,
        title: 'Safety Review',
        message: 'Your safety score dropped below 70. Review driving habits.',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ]);

    // Mock trip history
    for (int i = 0; i < 8; i++) {
      final routes = [
        'Warehouse → Delivery Hub',
        'Depot A → Client Site',
        'Hub-B → Distribution Center',
        'Factory → Port Terminal',
      ];
      _tripHistory.add(TripHistoryEntry(
        id: 'trip_$i',
        date: now.subtract(Duration(days: i, hours: rng.nextInt(8))),
        routeName: routes[i % routes.length],
        duration: Duration(minutes: 20 + rng.nextInt(90)),
        distanceKm: 3.0 + rng.nextDouble() * 25,
        averageSpeed: 35.0 + rng.nextDouble() * 30,
        safetyScore: 55 + rng.nextInt(40),
        alertCount: rng.nextInt(10),
      ));
    }

    // Mock biometric templates
    _biometricTemplates.addAll([
      BiometricTemplate(
        id: 'bio_face',
        type: BiometricType.face,
        enrolledAt: now.subtract(const Duration(days: 30)),
      ),
      BiometricTemplate(
        id: 'bio_finger',
        type: BiometricType.fingerprint,
        enrolledAt: now.subtract(const Duration(days: 28)),
      ),
    ]);
  }
}