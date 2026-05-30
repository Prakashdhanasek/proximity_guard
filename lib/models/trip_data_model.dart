class TripDataModel {
  final double currentSpeed; // km/h
  final double speedLimit;
  final double followingDistance; // meters
  final double safeFollowingDistance;
  final bool isInGeofence;
  final String routeName;
  final double routeProgress; // 0.0 - 1.0
  final Duration tripDuration;
  final double distanceCovered; // km

  const TripDataModel({
    this.currentSpeed = 0,
    this.speedLimit = 60,
    this.followingDistance = 50,
    this.safeFollowingDistance = 30,
    this.isInGeofence = true,
    this.routeName = 'Warehouse → Delivery Hub',
    this.routeProgress = 0.0,
    this.tripDuration = Duration.zero,
    this.distanceCovered = 0,
  });

  bool get isTooClose => followingDistance < safeFollowingDistance;
  bool get isOverSpeed => currentSpeed > speedLimit;

  TripDataModel copyWith({
    double? currentSpeed,
    double? speedLimit,
    double? followingDistance,
    double? safeFollowingDistance,
    bool? isInGeofence,
    String? routeName,
    double? routeProgress,
    Duration? tripDuration,
    double? distanceCovered,
  }) {
    return TripDataModel(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      speedLimit: speedLimit ?? this.speedLimit,
      followingDistance: followingDistance ?? this.followingDistance,
      safeFollowingDistance: safeFollowingDistance ?? this.safeFollowingDistance,
      isInGeofence: isInGeofence ?? this.isInGeofence,
      routeName: routeName ?? this.routeName,
      routeProgress: routeProgress ?? this.routeProgress,
      tripDuration: tripDuration ?? this.tripDuration,
      distanceCovered: distanceCovered ?? this.distanceCovered,
    );
  }
}
