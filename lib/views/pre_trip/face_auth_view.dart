import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../../core/face_auth_engine.dart';
import '../../core/monitor_state.dart' as sd;
import '../theme/app_theme.dart';

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

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildScannerFrame(authController.status),
              const SizedBox(height: 36),
              _buildStatusSection(context, authController),
              const Spacer(flex: 1),
              if (authController.status == AuthStatus.success)
                _buildContinueButton(context)
              else if (authController.status == AuthStatus.failed)
                _buildRetrySection(context, authController)
              else
                _buildBackButton(context, authController),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannerFrame(AuthStatus status) {
    Color glowColor;
    switch (status) {
      case AuthStatus.success:
        glowColor = AppTheme.success;
      case AuthStatus.failed:
        glowColor = AppTheme.danger;
      default:
        glowColor = AppTheme.primary;
    }

    return AvatarGlow(
      glowColor: glowColor,
      glowRadiusFactor: 0.3,
      animate: status == AuthStatus.inProgress,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: glowColor.withValues(alpha: 0.08),
          border: Border.all(color: glowColor, width: 3),
        ),
        child: ClipOval(child: _buildScannerContent(status, glowColor)),
      ),
    );
  }

  Widget _buildScannerContent(AuthStatus status, Color glowColor) {
    if (status == AuthStatus.success) {
      return Center(child: Icon(Icons.check_circle_rounded, size: 60, color: glowColor));
    }
    if (status == AuthStatus.failed) {
      return Center(child: Icon(Icons.error_rounded, size: 60, color: glowColor));
    }

    final cam = _camera;
    if (!_camReady || cam == null || cam.value.previewSize == null) {
      return Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: glowColor),
        ),
      );
    }

    final ps = cam.value.previewSize!;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ps.height,
            height: ps.width,
            child: CameraPreview(cam),
          ),
        ),
        SizedBox(
          width: 150,
          height: 150,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: glowColor,
            backgroundColor: glowColor.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, AuthController controller) {
    String title;
    Color titleColor = AppTheme.of(context).textPrimary;

    switch (controller.status) {
      case AuthStatus.success:
        title = 'Identity Verified';
        titleColor = AppTheme.accent;
      case AuthStatus.inProgress:
        title = (_camReady && _engineReady) ? 'Scanning...' : 'Getting Ready...';
      case AuthStatus.failed:
        title = 'Verification Failed';
        titleColor = AppTheme.danger;
      default:
        title = 'Face Authentication';
    }

    final subtitle = controller.status == AuthStatus.inProgress
        ? _hint
        : controller.message;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
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
              style: const TextStyle(
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

  Widget _buildBackButton(BuildContext context, AuthController controller) {
    return TextButton.icon(
      onPressed: () => controller.reset(),
      icon: Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.of(context).textSecondary),
      label: Text('Choose another method', style: TextStyle(color: AppTheme.of(context).textSecondary)),
    );
  }
}