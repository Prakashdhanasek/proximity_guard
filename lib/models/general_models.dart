import 'trip_alert_model.dart';

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

enum NotificationType {
  tamperAlert,
  unauthorizedAccess,
  managerMessage,
  systemUpdate,
  tripReminder,
  safetyWarning,
}

class TripHistoryEntry {
  final String id;
  final DateTime date;
  final String routeName;
  final Duration duration;
  final double distanceKm;
  final double averageSpeed;
  final int safetyScore;
  final int alertCount;

  const TripHistoryEntry({
    required this.id,
    required this.date,
    required this.routeName,
    required this.duration,
    required this.distanceKm,
    required this.averageSpeed,
    required this.safetyScore,
    required this.alertCount,
  });

  String get formattedDate {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get formattedDistance {
    if (distanceKm >= 1) return '${distanceKm.toStringAsFixed(1)} km';
    return '${(distanceKm * 1000).toInt()} m';
  }
}

class BiometricTemplate {
  final String id;
  final BiometricType type;
  final DateTime enrolledAt;
  final bool isActive;

  const BiometricTemplate({
    required this.id,
    required this.type,
    required this.enrolledAt,
    this.isActive = true,
  });
}

enum BiometricType { face, fingerprint, voice }
