import 'trip_alert_model.dart';

class TripSummaryModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceKm;
  final String routeName;
  final double averageSpeed;
  final double maxSpeed;
  final double speedLimit;
  final int safetyScore; // 0-100
  final List<TripAlertModel> alerts;
  final List<TripIncident> incidents;
  final SafetyBreakdown safetyBreakdown;

  const TripSummaryModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceKm,
    required this.routeName,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.speedLimit,
    required this.safetyScore,
    required this.alerts,
    required this.incidents,
    required this.safetyBreakdown,
  });

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String get formattedDistance {
    if (distanceKm >= 1) return '${distanceKm.toStringAsFixed(1)} km';
    return '${(distanceKm * 1000).toInt()} m';
  }

  int get criticalAlertCount =>
      alerts.where((a) => a.severity == AlertSeverity.critical).length;
  int get highAlertCount =>
      alerts.where((a) => a.severity == AlertSeverity.high).length;

  String get scoreGrade {
    if (safetyScore >= 90) return 'A';
    if (safetyScore >= 80) return 'B';
    if (safetyScore >= 70) return 'C';
    if (safetyScore >= 60) return 'D';
    return 'F';
  }
}

class TripIncident {
  final String id;
  final TripAlertModel alert;
  final Duration timestampInTrip;
  final bool hasVideo;

  const TripIncident({
    required this.id,
    required this.alert,
    required this.timestampInTrip,
    this.hasVideo = false,
  });

  String get formattedTimestamp {
    final m = timestampInTrip.inMinutes;
    final s = timestampInTrip.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class SafetyBreakdown {
  final int followingDistanceScore; // 0-100
  final int speedComplianceScore;
  final int alertResponseScore;
  final int attentivenessScore;

  const SafetyBreakdown({
    required this.followingDistanceScore,
    required this.speedComplianceScore,
    required this.alertResponseScore,
    required this.attentivenessScore,
  });
}

class DrivingTrend {
  final DateTime date;
  final int safetyScore;
  final double distanceKm;
  final int alertCount;

  const DrivingTrend({
    required this.date,
    required this.safetyScore,
    required this.distanceKm,
    required this.alertCount,
  });
}
