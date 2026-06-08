import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../../core/face_auth_engine.dart';
import '../../core/monitor_state.dart' as sd;
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';

/// Live face verification screen.
class FaceAuthView extends StatefulWidget {
  const FaceAuthView({super.key});

  @override
  State<FaceAuthView> createState() => _FaceAuthViewState();
}

class _FaceAuthViewState extends State<FaceAuthView> {
  CameraController? _camera;
  FaceDetector? _detector;
  final FaceAuthEngine _engine = FaceAuthEngine();
  final sd.MonitorState _monitor = sd.MonitorState();

  bool _camReady = false;
  bool _streaming = false;
  bool _isProcessing = false;
  bool _done = false;
  bool _engineReady = false;
  bool _scanStarted = false;
  int _frameIndex = 0;
  String _hint = 'Getting ready...';

  Timer? _timeout;
  static const Duration _kTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableLandmarks: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    // Camera FIRST: this triggers the OS camera-permission prompt right away and
    // gets the preview on screen, BEFORE the heavy (CPU-bound) face enrollment
    // runs. Otherwise enrollment hogs the main thread and the permission dialog
    // only appears after a long "loading" delay.
    await _initCamera();

    // Now load the face model + enrollment in the background.
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await _engine.initialize();
    } catch (e) {
      if (mounted) _setHint('Face model failed to load');
      return;
    }
    if (!mounted) return;
    _engineReady = true;
    _maybeStartScanning();
  }

  /// Begins the actual scan (and the timeout) only once BOTH the camera preview
  /// and the face model are ready — until then the UI shows "Getting Ready...".
  void _maybeStartScanning() {
    if (_scanStarted || _done || !_camReady || !_engineReady) return;
    _scanStarted = true;
    _setHint('Position your face in the frame');
    _timeout?.cancel();
    _timeout = Timer(_kTimeout, () {
      if (!_done && mounted) {
        _fail('Face not recognized. Please try again.');
      }
    });
    if (mounted) setState(() {}); // flip title to "Scanning..."
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
      if (front == null) {
        _setHint('No camera found');
        return;
      }

      debugPrint('[AuthDBG] front camera sensorOrientation=${front.sensorOrientation} lens=${front.lensDirection}');

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
      setState(() {
        _camReady = true;
        _hint = _engineReady ? 'Position your face in the frame' : 'Preparing face model...';
      });
      await controller.startImageStream(_processImage);
      _streaming = true;
      _maybeStartScanning();
    } catch (e) {
      _setHint('Camera error — check permissions');
    }
  }

  void _setHint(String h) {
    if (mounted) setState(() => _hint = h);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_done || _isProcessing || !_camReady || _detector == null) return;
    _isProcessing = true;
    _frameIndex++;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        debugPrint('[AuthDBG] inputImage NULL (rotation unresolved)');
        return;
      }

      final allFaces = await _detector!.processImage(inputImage);
      final faces = allFaces.where((f) => f.boundingBox.width > 50).toList();

      if (_frameIndex % 10 == 0) {
        debugPrint('[AuthDBG] frame=$_frameIndex detected=${allFaces.length} afterFilter=${faces.length}');
      }

      if (faces.length > 1) {
        _setHint('Only one person in frame, please');
      } else if (faces.length == 1) {
        if (!_engineReady) {
          _setHint('Preparing face model...');
        } else {
          // Run the match on EVERY processed frame (was every 5th). The
          // _isProcessing guard prevents overlap, so this self-throttles and
          // reaches the 2 consecutive matches the engine needs much faster.
          _engine.processAuth(
            faces.first,
            _monitor,
            image,
            _camera!.description.sensorOrientation,
          );
          _setHint('Verifying... (match: ${_monitor.authDistance.toStringAsFixed(2)})');
          if (_monitor.authStatus == sd.AuthStatus.authenticated) {
            _onSuccess();
          }
        }
      } else {
        _setHint(_engineReady ? 'Position your face in the frame' : 'Preparing face model...');
      }
    } catch (e) {
      debugPrint('[AuthDBG] _processImage error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // Maps each reference folder to the driver's display name.
  static const Map<String, String> _driverNames = {
    'Authorized_driver_1': 'Rohit',
    'Authorized_driver_2': 'Ajay',
    'Authorized_driver_3': 'Maneesha',
    'Authorized_driver_4': 'Sruthy',
  };

  void _onSuccess() {
    if (_done) return;
    _done = true;
    _timeout?.cancel();
    final label = _engine.lastMatchedLabel;
    final name = _driverNames[label];
    debugPrint('[AuthDBG] AUTHENTICATED as $label -> ${name ?? 'default'}');
    context.read<AuthController>().completeFaceAuth(driverName: name);
  }

  void _fail(String msg) {
    if (_done) return;
    _done = true;
    _timeout?.cancel();
    debugPrint('[AuthDBG] FAILED: $msg (last distance=${_monitor.authDistance.toStringAsFixed(3)})');
    context.read<AuthController>().failFaceAuth(msg);
  }

  void _retry() {
    _monitor.authStatus = sd.AuthStatus.scanning;
    _monitor.authDistance = -1.0;
    _done = false;
    _frameIndex = 0;
    _setHint('Position your face in the frame');
    context.read<AuthController>().authenticateWithFace();
    _timeout?.cancel();
    _timeout = Timer(_kTimeout, () {
      if (!_done && mounted) _fail('Face not recognized. Please try again.');
    });
  }

  // ── Rotation for ML Kit ─────────────────────────────────────────────────────
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
      // Build a PROPER NV21 buffer that respects row/pixel stride.
      // (Naive plane concatenation breaks on devices where rowStride != width,
      //  which makes ML Kit see garbage and detect zero faces.)
      final nv21 = _yuv420ToNv21(image);
      return InputImage.fromBytes(
        bytes: nv21,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width, // Y rows are now tightly packed
        ),
      );
    } else {
      // iOS: single BGRA plane
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

  /// Converts a YUV_420_888 [CameraImage] (3 planes) into a packed NV21 buffer
  /// (Y plane followed by interleaved V,U), correctly handling row stride and
  /// pixel stride. This is what ML Kit needs on Android.
  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int ySize = width * height;
    final int uvSize = (width ~/ 2) * (height ~/ 2) * 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // --- Copy Y plane (respect row stride) ---
    final int yRowStride = yPlane.bytesPerRow;
    int pos = 0;
    if (yRowStride == width) {
      nv21.setRange(0, ySize, yPlane.bytes);
      pos = ySize;
    } else {
      final yb = yPlane.bytes;
      for (int row = 0; row < height; row++) {
        final int start = row * yRowStride;
        nv21.setRange(pos, pos + width, yb, start);
        pos += width;
      }
    }

    // --- Interleave V,U (NV21 ordering) ---
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
        final int v = uvOffset < vb.length ? vb[uvOffset] : 0;
        final int u = uvOffset < ub.length ? ub[uvOffset] : 0;
        nv21[pos++] = v;
        nv21[pos++] = u;
      }
    }
    return nv21;
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final cam = _camera;
    if (cam != null) {
      if (_streaming) {
        cam.stopImageStream().catchError((_) {});
      }
      cam.dispose();
    }
    _detector?.close();
    super.dispose();
  }

  // ─── UI (redesigned to match the mock) ──────────────────────────────────────

  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _ringTrack = Color(0xFFE6E9F1);
  static const Color _tipsBg = Color(0xFFF3F5F9);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final status = authController.status;

        // Success gets its own celebratory layout (matches the mock).
        if (status == AuthStatus.success) {
          return _buildSuccessView(context, authController);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildScannerFrame(status),
              const SizedBox(height: 30),
              _buildStatusSection(context, authController),
              const Spacer(flex: 3),
              if (status == AuthStatus.failed)
                _buildRetrySection(context, authController)
              else
                _buildTipsCard(),
            ],
          ),
        );
      },
    );
  }

  // ── Success layout ──────────────────────────────────────────────────────────
  Widget _buildSuccessView(BuildContext context, AuthController controller) {
    final driver = controller.authenticatedDriver;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          const Spacer(flex: 1),
          _buildConfettiCircle(),
          const SizedBox(height: 22),
          Image.asset(AppImages.verify, width: 52, height: 52),
          const SizedBox(height: 14),
          Text(
            'Identity Verified!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have been successfully verified',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
          ),
          const SizedBox(height: 22),
          Text(
            'Welcome back,',
            style: GoogleFonts.poppins(fontSize: 14, color: _textGrey),
          ),
          const SizedBox(height: 4),
          Text(
            driver?.name ?? 'Driver',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          if (driver != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Driver ID: ${driver.id}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
          const Spacer(flex: 2),
          _buildContinueButton(context),
        ],
      ),
    );
  }

  /// Live camera circle with a green ring + light confetti scattered around it.
  Widget _buildConfettiCircle() {
    const amber = Color(0xFFF5C842);
    return SizedBox(
      width: double.infinity,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── left side scatter ──
          Positioned(left: 16, top: 152, child: _diamond(AppTheme.primary, 11)),
          Positioned(left: 58, top: 112, child: _dot(AppTheme.success, 7)),
          Positioned(left: 40, top: 74, child: _dot(AppTheme.success, 5)),
          Positioned(left: 62, top: 170, child: _diamond(AppTheme.success, 8)),
          Positioned(left: 22, top: 206, child: _diamond(amber, 9)),
          Positioned(left: 64, top: 200, child: _dot(AppTheme.success, 5)),
          Positioned(left: 30, top: 122, child: _dot(amber, 4)),
          Positioned(left: 50, top: 146, child: _dot(AppTheme.primary, 4)),
          Positioned(left: 18, top: 96, child: _dot(AppTheme.success, 4)),
          Positioned(left: 44, top: 44, child: _dot(AppTheme.primary, 4)),
          // ── right side scatter ──
          Positioned(right: 16, top: 152, child: _diamond(AppTheme.primary, 11)),
          Positioned(right: 58, top: 112, child: _dot(AppTheme.primary, 7)),
          Positioned(right: 40, top: 74, child: _dot(AppTheme.success, 5)),
          Positioned(right: 62, top: 170, child: _diamond(AppTheme.success, 8)),
          Positioned(right: 22, top: 206, child: _diamond(amber, 9)),
          Positioned(right: 64, top: 200, child: _dot(AppTheme.success, 5)),
          Positioned(right: 30, top: 122, child: _dot(amber, 4)),
          Positioned(right: 50, top: 146, child: _dot(AppTheme.success, 4)),
          Positioned(right: 18, top: 96, child: _dot(AppTheme.primary, 4)),
          Positioned(right: 44, top: 44, child: _dot(AppTheme.success, 4)),
          // circle (drawn last, sits above the scatter)
          _buildScannerFrame(AuthStatus.success),
        ],
      ),
    );
  }

  Widget _dot(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _diamond(Color color, double size) => Transform.rotate(
        angle: 0.785398, // 45°
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildScannerFrame(AuthStatus status) {
    Color ringColor;
    switch (status) {
      case AuthStatus.success:
        ringColor = AppTheme.success;
      case AuthStatus.failed:
        ringColor = AppTheme.danger;
      default:
        ringColor = AppTheme.primary;
    }

    const double size = 200;
    const double inner = 172;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Live camera circle
          Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColor.withValues(alpha: 0.06),
              border: Border.all(color: _ringTrack, width: 1),
            ),
            child: ClipOval(child: _buildScannerContent(status, ringColor)),
          ),
          // Scanning ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              value: status == AuthStatus.inProgress ? null : 1,
              valueColor: AlwaysStoppedAnimation(ringColor),
              backgroundColor: _ringTrack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerContent(AuthStatus status, Color ringColor) {
    if (status == AuthStatus.failed) {
      return Center(
          child: Icon(Icons.error_rounded, size: 64, color: ringColor));
    }

    final cam = _camera;
    if (!_camReady || cam == null || cam.value.previewSize == null) {
      return Center(
        child: SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: ringColor),
        ),
      );
    }

    final ps = cam.value.previewSize!;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: ps.height,
        height: ps.width,
        child: CameraPreview(cam),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AuthController controller) {
    String title;
    Color titleColor;
    String subtitle;

    switch (controller.status) {
      case AuthStatus.success:
        title = 'Identity Verified';
        titleColor = AppTheme.accent;
        subtitle = controller.message;
      case AuthStatus.failed:
        title = 'Verification Failed';
        titleColor = AppTheme.danger;
        subtitle = controller.message;
      default:
        title = 'Look at the camera';
        titleColor = AppTheme.primary;
        subtitle = 'Position your face in the frame\nto verify your identity';
    }

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            height: 1.4,
            color: _textGrey,
          ),
        ),
        if (controller.status == AuthStatus.success &&
            controller.authenticatedDriver != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              controller.authenticatedDriver!.name,
              style: GoogleFonts.poppins(
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tipsBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(AppImages.tips, width: 26, height: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Make sure your face is clearly visible and well lit.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.35,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return AppTheme.gradientButton(
      label: 'Continue',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => context.read<PreTripController>().onAuthSuccess(),
    );
  }

  Widget _buildRetrySection(BuildContext context, AuthController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => controller.reset(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}