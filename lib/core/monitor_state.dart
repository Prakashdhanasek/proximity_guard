// lib/core/monitor_state.dart
// Central state model for the entire monitoring pipeline

enum AuthStatus { scanning, authenticated, unauthorized, multipleFaces }
enum DrowsinessLevel { alert, drowsy, asleep }
enum DistractionStatus { forward, distracted }
enum MonitorMode { normal, sunglasses, oneEye }

class AlertEvent {
  final String type;
  final String message;
  final DateTime timestamp;
  final bool needsScreenshot;
  final bool isMajorFlag;
  String? screenshotPath;

  AlertEvent({
    required this.type,
    required this.message,
    this.needsScreenshot = false,
    this.isMajorFlag = false,
  }) : timestamp = DateTime.now();
}

class MonitorState {
  // Auth
  AuthStatus authStatus = AuthStatus.scanning;
  double authDistance = -1.0;  // live distance score — shown in diag for threshold tuning
  int? authenticatedTrackingId; // Maintain auth if MLKit tracking confirms it's the same physical face
  int faceCount = 0;           // number of faces seen in current frame
  bool seatbeltBuckled = false;
  DateTime? lastSeatbeltDetected;

  // Calibration
  bool calibrated = false;
  int calibrationFrame = 0;

  // Mode
  MonitorMode monitorMode = MonitorMode.normal;
  String oneEyeSide = '';

  // EAR
  double leftEar = 0.0;
  double rightEar = 0.0;
  double earBaseline = 0.28;
  double earThreshold = 0.21;
  List<double> calibrationEarValues = [];

  // Drowsiness timer
  DateTime? eyesClosedSince;
  DateTime? eyesOpenSince;
  DrowsinessLevel drowsinessLevel = DrowsinessLevel.alert;
  int totalDrowsyCount = 0;

  // MAR (sunglasses mode)
  double mar = 0.0;
  DateTime? yawningSince;

  // Head pose
  double yaw = 0.0;
  double pitch = 0.0;
  DistractionStatus distractionStatus = DistractionStatus.forward;
  DateTime? distractedSince;
  DateTime? headDropSince;

  // Blink tracking
  List<DateTime> blinkTimestamps = [];
  List<double> recentEarHistory = []; // For rolling variance / sunglasses detection
  double blinkBaseline = 0.0;
  bool blinkBaselineSet = false;
  DateTime? blinkBaselineStart;
  int blinkBaselineCount = 0;
  bool impairmentFlag = false;
  DateTime? impairmentFlaggedSince;
  DateTime? impairmentSuppressedUntil;
  bool lastEyeStateOpen = true;

  // Driver historical baseline (Substance Abuse Tracker)
  double headSwayBaseline = 0.0;
  List<double> headPitchHistory = [];
  List<double> headYawHistory = [];

  // Distraction tracking
  int totalDistractionCount = 0;
  DateTime? lastDistractionFlagTime;

  // Object detection
  List<DetectedObject> detectedObjects = [];

  // Alert log
  List<AlertEvent> recentAlerts = [];
  Map<String, DateTime> lastScreenshotTime = {};

  // Frame counters
  int frameCount = 0;

  void addAlert(AlertEvent e) {
    recentAlerts.insert(0, e);
    if (recentAlerts.length > 20) recentAlerts.removeLast();
  }

  /// Reset calibration — called when driver changes or auth is revoked
  void resetCalibration() {
    calibrated = false;
    calibrationFrame = 0;
    calibrationEarValues.clear();
    earBaseline = 0.28;
    earThreshold = 0.21;
    monitorMode = MonitorMode.normal;
    oneEyeSide = '';
    blinkBaselineSet = false;
    blinkBaselineStart = null;
    blinkTimestamps.clear();
    impairmentFlag = false;
    impairmentFlaggedSince = null;
    drowsinessLevel = DrowsinessLevel.alert;
    totalDrowsyCount = 0;
    distractionStatus = DistractionStatus.forward;
    eyesClosedSince = null;
    eyesOpenSince = null;
    distractedSince = null;
    headDropSince = null;
    seatbeltBuckled = false;
    totalDistractionCount = 0;
    lastDistractionFlagTime = null;
    headSwayBaseline = 0.0;
    headPitchHistory.clear();
    headYawHistory.clear();
    recentEarHistory.clear();
  }
}

class DetectedObject {
  final String label;
  final double confidence;
  final double x, y, width, height; // normalized 0-1
  DetectedObject({
    required this.label,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
