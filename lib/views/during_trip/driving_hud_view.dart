import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/views/live_route_map.dart';
import '../../controllers/trip_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/general_models.dart';
import '../../models/trip_data_model.dart';
import '../../models/trip_alert_model.dart';
import '../../core/monitor_state.dart' as sd;
import '../../core/monitoring_engine.dart';
import '../../core/object_detector_engine.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';
import '../general/settings_hub_view.dart';
import '../post_trip/post_trip_summary_view.dart';
import 'trip_alert_overlay.dart';

class DrivingHudView extends StatefulWidget {
  const DrivingHudView({super.key});

  @override
  State<DrivingHudView> createState() => _DrivingHudViewState();
}

class _DrivingHudViewState extends State<DrivingHudView> {
  // ── Camera monitoring pipeline ─────────────────────────────────────────────
  CameraController? _camera;
  FaceDetector? _detector;
  late final sd.MonitorState _monitor;
  late final MonitoringEngine _monitoringEngine;
  final ObjectDetectorEngine _objectDetector = ObjectDetectorEngine();
  final AudioPlayer _audioPlayer = AudioPlayer();

  TripController? _trip;
  SettingsController? _settings;
  DateTime _lastAlarmTime = DateTime(2000);
  final Map<String, DateTime> _lastNotify = {};
  bool _camReady = false;
  bool _streaming = false;
  bool _isProcessing = false;
  int _frameIndex = 0;

  // When true, the camera fills the screen and the HUD shrinks to a thumbnail.
  bool _cameraExpanded = false;

  // Transition trackers so we only push an alert on state changes.
  sd.DrowsinessLevel _lastDrowsy = sd.DrowsinessLevel.alert;
  sd.DistractionStatus _lastDistract = sd.DistractionStatus.forward;

  // Palette (light design)
  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _cardBorder = Color(0xFFEDEFF4);

  @override
  void initState() {
    super.initState();
    _monitor = sd.MonitorState();
    _monitoringEngine = MonitoringEngine(_monitor);
    _initMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trip ??= context.read<TripController>();
    _settings ??= context.read<SettingsController>();
  }

  Future<void> _initMonitoring() async {
    try {
      await _objectDetector.initialize();
    } catch (_) {}

    if (!mounted) return;

    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableLandmarks: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      CameraDescription? front;
      for (final c in cams) {
        if (c.lensDirection == CameraLensDirection.front) {
          front = c;
          break;
        }
      }
      front ??= cams.isNotEmpty ? cams.first : null;
      if (front == null) return;

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = controller;
      setState(() => _camReady = true);
      await controller.startImageStream(_processImage);
      _streaming = true;
    } catch (_) {}
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_camReady || _detector == null) return;
    _isProcessing = true;
    _frameIndex++;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final allFaces = await _detector!.processImage(inputImage);
      final faces = allFaces.where((f) => f.boundingBox.width > 50).toList();
      _monitor.faceCount = faces.length;

      if (_frameIndex % 30 == 0) {
        debugPrint('[MonitorDBG] frame=$_frameIndex faces=${faces.length} cal=${_monitor.calibrated}(${_monitor.calibrationFrame}) drowsy=${_monitor.drowsinessLevel} distract=${_monitor.distractionStatus} objects=${_monitor.detectedObjects.length}');
      }

      if (faces.length == 1) {
        _monitoringEngine.processFrame(faces.first);
      } else {
        _monitoringEngine.processFrame(null);
      }

      _pushDrowsinessAndDistraction();

      if (_frameIndex % 30 == 0) {
        _objectDetector.processFrame(
          image,
          _monitor,
          _camera!.description.sensorOrientation,
        );
        _pushBannedObjects();
      }

      _handleAlarms();
    } catch (_) {
    } finally {
      _isProcessing = false;
      if (_cameraExpanded && mounted) setState(() {});
    }
  }

  void _handleAlarms() {
    final now = DateTime.now();
    final msSinceLast = now.difference(_lastAlarmTime).inMilliseconds;

    String? soundAsset;
    if (_monitor.drowsinessLevel == sd.DrowsinessLevel.asleep && msSinceLast > 1500) {
      soundAsset = 'audio/alert_loud.mp3';
    } else if ((_monitor.drowsinessLevel == sd.DrowsinessLevel.drowsy ||
            _monitor.distractionStatus == sd.DistractionStatus.distracted ||
            _monitor.detectedObjects.isNotEmpty) &&
        msSinceLast > 3000) {
      soundAsset = 'audio/alert_soft.mp3';
    }

    if (soundAsset != null) {
      _lastAlarmTime = now;
      _audioPlayer.play(AssetSource(soundAsset)).catchError((e) {
        debugPrint('[Audio] Play error: $e');
      });
    }
  }

  void _notify(String key, String title, String message) {
    final settings = _settings;
    if (settings == null) return;
    final now = DateTime.now();
    final last = _lastNotify[key];
    if (last != null && now.difference(last).inSeconds < 8) return;
    _lastNotify[key] = now;
    settings.addNotification(
      type: NotificationType.safetyWarning,
      title: title,
      message: message,
    );
  }

  void _pushDrowsinessAndDistraction() {
    final trip = _trip;
    if (trip == null) return;

    if (_monitor.drowsinessLevel != _lastDrowsy) {
      _lastDrowsy = _monitor.drowsinessLevel;
      if (_monitor.drowsinessLevel == sd.DrowsinessLevel.asleep) {
        trip.pushCameraAlert(
          type: AlertType.drowsiness,
          severity: AlertSeverity.critical,
          title: 'Drowsiness Detected',
          message: 'Eyes closed / head dropping — wake up and take a break.',
        );
        _notify('drowsy', 'Drowsiness Alert',
            'Driver appears asleep at the wheel. Immediate attention needed.');
      } else if (_monitor.drowsinessLevel == sd.DrowsinessLevel.drowsy) {
        trip.pushCameraAlert(
          type: AlertType.drowsiness,
          severity: AlertSeverity.high,
          title: 'Drowsiness Detected',
          message: 'Signs of drowsiness detected. Consider taking a break.',
        );
        _notify('drowsy', 'Drowsiness Detected',
            'Signs of drowsiness detected during the trip.');
      }
    }

    if (_monitor.distractionStatus != _lastDistract) {
      _lastDistract = _monitor.distractionStatus;
      if (_monitor.distractionStatus == sd.DistractionStatus.distracted) {
        trip.pushCameraAlert(
          type: AlertType.distraction,
          severity: AlertSeverity.high,
          title: 'Distraction Alert',
          message: 'Eyes off the road. Keep your focus ahead.',
        );
        _notify('distract', 'Distraction Alert',
            'Driver was looking away from the road.');
      }
    }
  }

  void _pushBannedObjects() {
    final trip = _trip;
    if (trip == null) return;

    for (final sd.DetectedObject obj in _monitor.detectedObjects) {
      if (obj.label == 'Cell Phone') {
        trip.pushCameraAlert(
          type: AlertType.distraction,
          severity: AlertSeverity.high,
          title: 'Phone Detected',
          message: 'Put the phone away — keep both eyes on the road.',
        );
        _notify('obj_${obj.label}', 'Phone Usage Detected',
            'Mobile phone detected while driving.');
      } else if (['Bottle', 'Wine Glass', 'Cup'].contains(obj.label)) {
        trip.pushCameraAlert(
          type: AlertType.distraction,
          severity: AlertSeverity.medium,
          title: 'Drink Detected',
          message: 'No drinking while driving (${obj.label}).',
        );
        _notify('obj_${obj.label}', 'Drinking Detected',
            '${obj.label} detected in the vehicle while driving.');
      } else if (['Banana', 'Apple', 'Sandwich', 'Orange', 'Hot Dog', 'Pizza', 'Donut', 'Cake']
          .contains(obj.label)) {
        trip.pushCameraAlert(
          type: AlertType.distraction,
          severity: AlertSeverity.medium,
          title: 'Food Detected',
          message: 'No eating while driving (${obj.label}).',
        );
        _notify('obj_${obj.label}', 'Eating Detected',
            '${obj.label} detected in the vehicle while driving.');
      }
    }
  }

  InputImageRotation? _rotationFor(CameraController controller) {
    final sensorOrientation = controller.description.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    var rotationCompensation = 0;
    final orientation = controller.value.deviceOrientation;
    if (orientation == DeviceOrientation.portraitUp) {
      rotationCompensation = 0;
    } else if (orientation == DeviceOrientation.landscapeLeft) {
      rotationCompensation = 90;
    } else if (orientation == DeviceOrientation.portraitDown) {
      rotationCompensation = 180;
    } else if (orientation == DeviceOrientation.landscapeRight) {
      rotationCompensation = 270;
    }
    if (controller.description.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _camera;
    if (controller == null || image.planes.isEmpty) return null;

    final rotation = _rotationFor(controller);
    if (rotation == null) return null;

    if (Platform.isAndroid) {
      final nv21 = _yuv420ToNv21(image);
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
    } else {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int ySize = width * height;
    final int uvSize = (width ~/ 2) * (height ~/ 2) * 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    final int yRowStride = yPlane.bytesPerRow;
    int pos = 0;
    if (yRowStride == width) {
      nv21.setRange(0, ySize, yPlane.bytes);
      pos = ySize;
    } else {
      final yb = yPlane.bytes;
      for (int row = 0; row < height; row++) {
        nv21.setRange(pos, pos + width, yb, row * yRowStride);
        pos += width;
      }
    }

    final Uint8List ub = uPlane.bytes;
    final Uint8List vb = vPlane.bytes;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final int chromaH = height ~/ 2;
    final int chromaW = width ~/ 2;
    for (int row = 0; row < chromaH; row++) {
      final int rowStart = row * uvRowStride;
      for (int col = 0; col < chromaW; col++) {
        final int uvOffset = rowStart + col * uvPixelStride;
        nv21[pos++] = uvOffset < vb.length ? vb[uvOffset] : 0;
        nv21[pos++] = uvOffset < ub.length ? ub[uvOffset] : 0;
      }
    }
    return nv21;
  }

  @override
  void dispose() {
    final cam = _camera;
    if (cam != null) {
      if (_streaming) {
        cam.stopImageStream().catchError((_) {});
      }
      cam.dispose();
    }
    _detector?.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─── UI (new light design) ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<TripController>(
      builder: (context, tripController, _) {
        final data = tripController.tripData;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(context, tripController),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        transform: Matrix4.translationValues(0, -22, 0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                child: Column(
                                  children: [
                                    _buildSpeedCard(context, data),
                                    const SizedBox(height: 14),
                                    _buildDistanceCard(context, data),
                                    const SizedBox(height: 14),
                                    _buildLiveTracking(context, data),
                                    const SizedBox(height: 14),
                                    _buildStatsRow(context, data),
                                    const SizedBox(height: 14),
                                    _buildActionButtons(context, tripController),
                                  ],
                                ),
                              ),
                            ),
                            _buildBottomNav(context, tripController),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Monitoring camera: always-visible thumbnail / full-screen ──
                if (_camReady && _camera != null) ...[
                  if (_cameraExpanded)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => setState(() => _cameraExpanded = false),
                        child: _buildFullScreenCamera(),
                      ),
                    )
                  else
                    Positioned(
                      right: 14,
                      bottom: 180,
                      child: GestureDetector(
                        onTap: () => setState(() => _cameraExpanded = true),
                        child: _buildMonitorPreview(),
                      ),
                    ),
                ],

                if (_cameraExpanded)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _expandedActionButton(
                            icon: Icons.close_fullscreen_rounded,
                            label: 'Minimize',
                            color: AppTheme.primary,
                            onTap: () => setState(() => _cameraExpanded = false),
                          ),
                          const SizedBox(height: 12),
                          _expandedActionButton(
                            icon: Icons.stop_rounded,
                            label: 'End',
                            color: AppTheme.danger,
                            onTap: () => _showEndTripDialog(context, tripController),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (tripController.activeAlerts.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 70,
                    left: 16,
                    right: 16,
                    child: TripAlertOverlay(
                      alert: tripController.activeAlerts.first,
                      onDismiss: () => tripController.dismissAlert(
                        tripController.activeAlerts.first.id,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header (blue appbar) ──
  Widget _buildHeader(BuildContext context, TripController controller) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 36),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.appbar),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => _showEndTripDialog(context, controller),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Driving Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Proximity Guard Active',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF22C55E)),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF16A34A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _circleButton(
            icon: Icons.notifications_none_rounded,
            onTap: () => _showAlertsSheet(context, controller),
            badge: controller.activeAlerts.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primary, size: 19),
            ),
            if (badge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.danger, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Speed card ──
  Widget _buildSpeedCard(BuildContext context, TripDataModel data) {
    final isOver = data.isOverSpeed;
    final ratio = (data.currentSpeed / (data.speedLimit * 1.5)).clamp(0.0, 1.0);
    final accent = isOver ? AppTheme.danger : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Current Speed',
            style: GoogleFonts.poppins(color: _textGrey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _SpeedGaugePainter(progress: ratio, over: isOver),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.currentSpeed.toInt()}',
                      style: GoogleFonts.poppins(
                        color: isOver ? AppTheme.danger : _textDark,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    Text(
                      'km/h',
                      style: GoogleFonts.poppins(
                          color: _textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusPill(
                icon: isOver
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_outlined,
                text: isOver ? 'Over Limit' : 'Within Limit',
                color: isOver ? AppTheme.danger : AppTheme.success,
              ),
              const SizedBox(width: 10),
              _statusPill(
                icon: Icons.speed_rounded,
                text: 'Limit ${data.speedLimit.toInt()} km/h',
                color: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusPill(
      {required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Following distance card ──
  Widget _buildDistanceCard(BuildContext context, TripDataModel data) {
    final tooClose = data.isTooClose;
    final color = tooClose ? AppTheme.danger : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tooClose ? Icons.warning_rounded : Icons.shield_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Following Distance',
                  style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${data.followingDistance.toInt()} m',
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1),
                  ),
                  Text(
                    'ahead',
                    style:
                        GoogleFonts.poppins(color: _textGrey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tooClose ? 'Too Close' : 'Safe Distance',
                style: GoogleFonts.poppins(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Live tracking + map ──
  Widget _buildLiveTracking(BuildContext context, TripDataModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF22C55E)),
            ),
            const SizedBox(width: 8),
            Text(
              'Live Tracking',
              style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Icon(Icons.more_vert_rounded, color: _textGrey, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        LiveRouteMap(
          progress: data.routeProgress,
          routeName: data.routeName,
          isLive: true,
          inGeofence: data.isInGeofence,
          speedKmh: data.currentSpeed,
        ),
      ],
    );
  }

  // ── Stats row ──
  Widget _buildStatsRow(BuildContext context, TripDataModel data) {
    final duration = data.tripDuration;
    final timeStr =
        '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    final progress = data.routeProgress.clamp(0.0, 1.0);
    final covered = data.distanceCovered;
    final kmLeft = (progress > 0.0 && progress < 1.0)
        ? covered * (1 - progress) / progress
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        children: [
          _statCol(Icons.near_me_rounded, 'Distance',
              '${covered.toStringAsFixed(0)} km', const Color(0xFF0891B2)),
          _statDivider(),
          _statCol(Icons.flag_rounded, 'Km Left',
              '${kmLeft.toStringAsFixed(1)} km', AppTheme.primary),
          _statDivider(),
          _statCol(Icons.access_time_rounded, 'Duration', timeStr,
              const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(width: 1, height: 36, color: _cardBorder);

  Widget _statCol(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(color: _textGrey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
                color: _textDark, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── End Trip + SOS ──
  Widget _buildActionButtons(BuildContext context, TripController controller) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => _showEndTripDialog(context, controller),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.danger.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_settings_new_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('End Trip',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: () => _showSos(context),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sos_rounded,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Text('SOS',
                      style: GoogleFonts.poppins(
                          color: AppTheme.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom navigation ──
  Widget _buildBottomNav(BuildContext context, TripController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder)),
      ),
      child: Row(
        children: [
          _navItem(Icons.dashboard_rounded, 'Dashboard',
              active: true, onTap: () {}),
          _navItem(Icons.notifications_none_rounded, 'Alerts',
              badge: controller.activeAlerts.isNotEmpty
                  ? controller.activeAlerts.length
                  : null,
              onTap: () => _showAlertsSheet(context, controller)),
          _navItem(Icons.route_rounded, 'Trips', onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Trips — coming soon')),
            );
          }),
          _navItem(Icons.person_outline_rounded, 'Profile', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsHubView()),
            );
          }),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label,
      {bool active = false, int? badge, required VoidCallback onTap}) {
    final color = active ? AppTheme.primary : _textGrey;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 23),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text('$badge',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 10,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSos(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.danger.withValues(alpha: 0.1)),
                child: const Icon(Icons.sos_rounded,
                    color: AppTheme.danger, size: 30),
              ),
              const SizedBox(height: 16),
              Text('Send SOS?',
                  style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'An emergency alert will be sent to your fleet manager with your location.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: _textGrey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SOS alert sent')),
                        );
                      },
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Monitoring overlay (kept from the original) ────────────────────────────

  Widget _buildMonitorPreview() {
    final cam = _camera!;
    final ps = cam.value.previewSize;
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ps != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: ps.height,
                  height: ps.width,
                  child: CameraPreview(cam),
                ),
              ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF4ADE80)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MONITOR',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenCamera() {
    final cam = _camera!;
    final ps = cam.value.previewSize;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ps != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ps.height,
                height: ps.width,
                child: CameraPreview(cam),
              ),
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMonitorStatusBar(),
                const Spacer(),
                _buildMonitorBanner(),
                _buildMonitorDiag(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorStatusBar() {
    final calText = _monitor.calibrated
        ? 'CAL ✓'
        : 'CALIBRATING ${_monitor.calibrationFrame}/${MonitoringEngine.kCalibrationFrames}';
    final calColor = _monitor.calibrated ? Colors.greenAccent : Colors.amber;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Colors.black.withValues(alpha: 0.55),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF4ADE80)),
          ),
          const SizedBox(width: 6),
          Text('MONITORING',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(width: 12),
          Text(calText,
              style: GoogleFonts.poppins(
                  color: calColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('FACES: ${_monitor.faceCount}',
              style: GoogleFonts.poppins(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMonitorBanner() {
    Widget? banner;
    if (_monitor.drowsinessLevel == sd.DrowsinessLevel.asleep) {
      banner = _monitorBanner(Colors.red, '⚠  WAKE UP — ASLEEP AT WHEEL  ⚠', Colors.white, 20);
    } else if (_monitor.detectedObjects.isNotEmpty) {
      final obj = _monitor.detectedObjects.first;
      String msg = '📵  BANNED OBJECT: ${obj.label.toUpperCase()}';
      if (['Bottle', 'Wine Glass', 'Cup'].contains(obj.label)) {
        msg = '🍺  DRINK: ${obj.label.toUpperCase()}';
      } else if (['Banana', 'Apple', 'Sandwich', 'Orange', 'Hot Dog', 'Pizza', 'Donut', 'Cake']
          .contains(obj.label)) {
        msg = '🍔  FOOD: ${obj.label.toUpperCase()}';
      }
      banner = _monitorBanner(Colors.purple.shade700, msg, Colors.white, 17);
    } else if (_monitor.drowsinessLevel == sd.DrowsinessLevel.drowsy) {
      banner = _monitorBanner(Colors.orange, '⚠  DROWSINESS DETECTED  ⚠', Colors.white, 17);
    } else if (_monitor.distractionStatus == sd.DistractionStatus.distracted) {
      banner = _monitorBanner(Colors.yellow.shade700, '⚠  DISTRACTION DETECTED  ⚠', Colors.black, 17);
    }
    return banner ?? const SizedBox.shrink();
  }

  Widget _monitorBanner(Color bg, String text, Color fg, double size) {
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.all(14),
      child: Text(text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              color: fg, fontSize: size, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildMonitorDiag() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _monitorDiagRow('EAR',
              'L:${_monitor.leftEar.toStringAsFixed(3)}  R:${_monitor.rightEar.toStringAsFixed(3)}  Thr:${_monitor.earThreshold.toStringAsFixed(3)}'),
          _monitorDiagRow('HEAD',
              'Yaw:${_monitor.yaw.toStringAsFixed(1)}°  Pitch:${_monitor.pitch.toStringAsFixed(1)}°'),
          _monitorDiagRow('STATUS',
              '${_monitor.drowsinessLevel.name.toUpperCase()} | ${_monitor.distractionStatus.name.toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _monitorDiagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(value,
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _expandedActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Alerts sheet & dialogs (kept from the original) ────────────────────────

  void _showAlertsSheet(BuildContext context, TripController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final allAlerts = controller.alerts;
        final activeAlerts = controller.activeAlerts;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.of(context).cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trip Alerts',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.of(context).textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          Text('${activeAlerts.length} active · ${allAlerts.length} total',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.of(context).textMuted,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                    if (activeAlerts.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          for (final a in activeAlerts) {
                            controller.dismissAlert(a.id);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.of(context)
                                .textMuted
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Clear All',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.of(context).textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.of(context).cardBorder),
              if (allAlerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 48,
                          color: AppTheme.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No alerts yet',
                          style: GoogleFonts.poppins(
                              color: AppTheme.of(context).textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Drive safe!',
                          style: GoogleFonts.poppins(
                              color: AppTheme.of(context).textMuted,
                              fontSize: 11)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: allAlerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final alert = allAlerts[allAlerts.length - 1 - i];
                      final color = _sheetAlertColor(alert.severity);
                      final icon = _sheetAlertIcon(alert.type);
                      final isDismissed = alert.isDismissed;

                      return Opacity(
                        opacity: isDismissed ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDismissed
                                ? AppTheme.of(context).surface
                                : AppTheme.of(context).card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDismissed
                                  ? AppTheme.of(context).cardBorder
                                  : color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(alert.title,
                                        style: GoogleFonts.poppins(
                                            color: isDismissed
                                                ? AppTheme.of(context).textMuted
                                                : AppTheme.of(context)
                                                    .textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                    Text(alert.message,
                                        style: GoogleFonts.poppins(
                                            color:
                                                AppTheme.of(context).textMuted,
                                            fontSize: 9),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (!isDismissed)
                                GestureDetector(
                                  onTap: () => controller.dismissAlert(alert.id),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context)
                                          .cardBorder
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.close_rounded,
                                        size: 13,
                                        color: AppTheme.of(context).textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _sheetAlertColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => AppTheme.primary,
      AlertSeverity.medium => AppTheme.warning,
      AlertSeverity.high => AppTheme.danger,
      AlertSeverity.critical => const Color(0xFF991B1B),
    };
  }

  IconData _sheetAlertIcon(AlertType type) {
    return switch (type) {
      AlertType.forwardDistance => Icons.swap_horiz_rounded,
      AlertType.drowsiness => Icons.bedtime_rounded,
      AlertType.distraction => Icons.phone_android_rounded,
      AlertType.geofenceBreach => Icons.location_off_rounded,
      AlertType.speedLimit => Icons.speed_rounded,
    };
  }

  void _showEndTripDialog(BuildContext context, TripController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.danger.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.stop_circle_rounded,
                    size: 36, color: AppTheme.danger),
              ),
              const SizedBox(height: 20),
              Text('End Trip?',
                  style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'This will stop all monitoring and end the current driving session.',
                style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textSecondary,
                    fontSize: 11,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.of(context).textSecondary,
                        side:
                            BorderSide(color: AppTheme.of(context).cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        controller.endTrip();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const PostTripSummaryView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('End Trip',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean speed gauge (270° arc, no tick marks).
class _SpeedGaugePainter extends CustomPainter {
  final double progress;
  final bool over;

  _SpeedGaugePainter({required this.progress, required this.over});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFE6E9F1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final colors = over
        ? [const Color(0xFFDC2626), const Color(0xFFF87171)]
        : [const Color(0xFF2563EB), const Color(0xFF60A5FA)];

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: colors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round,
    );

    final endAngle = startAngle + sweepAngle * progress;
    final dot = Offset(center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle));
    canvas.drawCircle(dot, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
        dot,
        5,
        Paint()
          ..color = over ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(_SpeedGaugePainter old) =>
      old.progress != progress || old.over != over;
}