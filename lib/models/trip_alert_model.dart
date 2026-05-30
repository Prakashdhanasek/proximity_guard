enum AlertType {
  forwardDistance,
  drowsiness,
  distraction,
  geofenceBreach,
  speedLimit,
}

enum AlertSeverity { low, medium, high, critical }

class TripAlertModel {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isDismissed;

  TripAlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isDismissed = false,
  });

  TripAlertModel copyWith({bool? isDismissed}) {
    return TripAlertModel(
      id: id,
      type: type,
      severity: severity,
      title: title,
      message: message,
      timestamp: timestamp,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}
