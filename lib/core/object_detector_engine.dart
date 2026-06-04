// lib/core/object_detector_engine.dart
// YOLOv8 Object Detection via tflite_flutter
// Detects: cell phone, foods (banana, apple, sandwich, etc.), drinks (bottle, cup, wine glass)
//
// KEY FIXES vs v1:
// 1. Confidence threshold lowered to 0.35 (from 0.60) — phone held sideways often gets 0.40–0.55
// 2. Full IoU-based Non-Maximum Suppression (NMS) to eliminate duplicate boxes
// 3. Front-camera horizontal mirror flip applied before writing into input buffer

import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'monitor_state.dart';

class ObjectDetectorEngine {
  Interpreter? _interpreter;
  bool _isModelLoaded = false;

  // Pre-allocated buffers — reused every frame to avoid GC pressure
  late Float32List _inputBuffer;

  // YOLO detection confidence threshold
  // 0.15 is optimal for cell phone detection
  static const double kConfidenceThreshold = 0.15;
  // 0.40 is optimal for food/drinks to prevent false positives
  static const double kFoodConfidenceThreshold = 0.40;
  // IoU overlap threshold for NMS — boxes overlapping > 50% are merged
  static const double kIouThreshold = 0.50;

  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolov8n.tflite',
        options: options,
      );
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      if (inputShape.isEmpty || outputShape.isEmpty) {
        throw Exception('Invalid model shape');
      }

      _inputBuffer = Float32List(1 * 640 * 640 * 3);
      _isModelLoaded = true;
      print('[YOLO] Loaded yolov8n.tflite successfully! Input: $inputShape, Output: $outputShape');
    } catch (e) {
      print('[YOLO] Object detection disabled: $e');
      _isModelLoaded = false;
    }
  }

  void processFrame(CameraImage image, MonitorState state, int rotation) {
    if (!_isModelLoaded || _interpreter == null) {
      state.detectedObjects = [];
      return;
    }

    try {
      // 1. Convert YUV420 → RGB → 640x640 float tensor with camera rotation fix
      _convertYUV420ToYOLOInput(image, rotation);

      // 2. Run inference
      _interpreter!.getInputTensor(0).data = _inputBuffer.buffer.asUint8List();
      _interpreter!.invoke();

      // 3. Read output tensor directly — [1, 84, 8400] in flat layout
      final outputFloatView = Float32List.sublistView(
        _interpreter!.getOutputTensor(0).data,
      );

      // 4. Parse raw detections from output tensor
      final rawDetections = _parseDetections(outputFloatView);

      // 5. Apply IoU-based Non-Maximum Suppression
      final nmsResults = _applyNMS(rawDetections);

      // 6. Keep only one of each class (highest confidence)
      final uniqueObjects = <String, DetectedObject>{};
      for (final obj in nmsResults) {
        if (!uniqueObjects.containsKey(obj.label) ||
            obj.confidence > uniqueObjects[obj.label]!.confidence) {
          uniqueObjects[obj.label] = obj;
        }
      }

      state.detectedObjects = uniqueObjects.values.toList();

      // 7. Add alerts for banned objects
      for (final obj in state.detectedObjects) {
        if (obj.label == 'Cell Phone') {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'BANNED OBJECT: CELL PHONE',
          ));
        } else if (['Bottle', 'Wine Glass', 'Cup'].contains(obj.label)) {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'BANNED DRINK: ${obj.label.toUpperCase()}',
          ));
        } else if ([
          'Banana', 'Apple', 'Sandwich', 'Orange',
          'Hot Dog', 'Pizza', 'Donut', 'Cake'
        ].contains(obj.label)) {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'BANNED FOOD: ${obj.label.toUpperCase()}',
          ));
        } else if (obj.label == 'Mouse') {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'BANNED OBJECT: COMPUTER MOUSE',
          ));
        }
      }
    } catch (e) {
      print('[YOLO] Inference error: $e');
    }
  }

  // ── Detection Parsing ───────────────────────────────────────────────────────

  // Target COCO classes (0-indexed):
  // 39=bottle, 40=wine glass, 41=cup
  // 46=banana, 47=apple, 48=sandwich, 49=orange, 52=hot dog, 53=pizza, 54=donut, 55=cake
  // 67=cell phone
  static const Map<int, String> _targets = {
    39: 'Bottle',
    40: 'Wine Glass',
    41: 'Cup',
    46: 'Banana',
    47: 'Apple',
    48: 'Sandwich',
    49: 'Orange',
    52: 'Hot Dog',
    53: 'Pizza',
    54: 'Donut',
    55: 'Cake',
    64: 'Mouse',
    67: 'Cell Phone',
  };

  List<DetectedObject> _parseDetections(Float32List output) {
    const int numBoxes = 8400;
    final List<DetectedObject> found = [];

    for (int col = 0; col < numBoxes; col++) {
      // Find best class among the 80 class scores (rows 4..83)
      double maxProb = 0.0;
      int bestClass = -1;

      for (int cls = 0; cls < 80; cls++) {
        final prob = output[(4 + cls) * numBoxes + col];
        if (prob > maxProb) {
          maxProb = prob;
          bestClass = cls;
        }
      }

      if (maxProb > 0.15 && _targets.containsKey(bestClass)) {
        print('[YOLO-DEBUG] Candidate ${_targets[bestClass]} at conf: $maxProb');
      }

      if (maxProb >= kConfidenceThreshold && _targets.containsKey(bestClass)) {
        // Apply stricter threshold for food and drinks
        final isFoodOrDrink = [39, 40, 41, 46, 47, 48, 49, 52, 53, 54, 55].contains(bestClass);
        if (isFoodOrDrink && maxProb < kFoodConfidenceThreshold) {
          continue;
        }

        // YOLOv8 outputs cx, cy, w, h in pixel coords (0–640)
        final cx = output[col] / 640.0;
        final cy = output[numBoxes + col] / 640.0;
        final w = output[2 * numBoxes + col] / 640.0;
        final h = output[3 * numBoxes + col] / 640.0;

        found.add(DetectedObject(
          label: _targets[bestClass]!,
          confidence: maxProb,
          x: cx - w / 2,
          y: cy - h / 2,
          width: w,
          height: h,
        ));
      }
    }

    return found;
  }

  // ── Non-Maximum Suppression ─────────────────────────────────────────────────
  List<DetectedObject> _applyNMS(List<DetectedObject> detections) {
    if (detections.isEmpty) return [];

    // Sort by descending confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectedObject> result = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        // Only suppress boxes of the same class
        if (detections[i].label == detections[j].label) {
          if (_iou(detections[i], detections[j]) > kIouThreshold) {
            suppressed[j] = true;
          }
        }
      }
    }

    return result;
  }

  /// Compute Intersection over Union between two bounding boxes
  double _iou(DetectedObject a, DetectedObject b) {
    final interX1 = a.x > b.x ? a.x : b.x;
    final interY1 = a.y > b.y ? a.y : b.y;
    final interX2 = (a.x + a.width) < (b.x + b.width) ? (a.x + a.width) : (b.x + b.width);
    final interY2 = (a.y + a.height) < (b.y + b.height) ? (a.y + a.height) : (b.y + b.height);

    if (interX2 <= interX1 || interY2 <= interY1) return 0.0;

    final intersection = (interX2 - interX1) * (interY2 - interY1);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final union = areaA + areaB - intersection;

    return union <= 0 ? 0.0 : intersection / union;
  }

  // ── YUV420 → 640x640 Float32 Input Buffer ──────────────────────────────────
  void _convertYUV420ToYOLOInput(CameraImage image, int rotation) {
    final int srcWidth = image.width;
    final int srcHeight = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final Uint8List yBytes = yPlane.bytes;
    final Uint8List uBytes = uPlane.bytes;
    final Uint8List vBytes = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    int bufferIdx = 0;

    for (int ty = 0; ty < 640; ty++) {
      for (int tx = 0; tx < 640; tx++) {
        int sx = 0;
        int sy = 0;

        // Front camera is horizontally mirrored on most Android devices.
        // Apply mirror flip on the X-axis and rotation compensation together.
        int mtx = 639 - tx; // horizontal mirror for front camera

        if (rotation == 90) {
          sx = ((ty * srcWidth) ~/ 640).clamp(0, srcWidth - 1);
          sy = (((639 - mtx) * srcHeight) ~/ 640).clamp(0, srcHeight - 1);
        } else if (rotation == 270) {
          sx = (((639 - ty) * srcWidth) ~/ 640).clamp(0, srcWidth - 1);
          sy = ((mtx * srcHeight) ~/ 640).clamp(0, srcHeight - 1);
        } else if (rotation == 180) {
          sx = (((639 - mtx) * srcWidth) ~/ 640).clamp(0, srcWidth - 1);
          sy = (((639 - ty) * srcHeight) ~/ 640).clamp(0, srcHeight - 1);
        } else {
          sx = ((mtx * srcWidth) ~/ 640).clamp(0, srcWidth - 1);
          sy = ((ty * srcHeight) ~/ 640).clamp(0, srcHeight - 1);
        }

        final int yIdx = sy * yRowStride + sx;
        final int uvIdx = (sy >> 1) * uvRowStride + (sx >> 1) * uvPixelStride;

        final int yVal = yIdx < yBytes.length ? yBytes[yIdx] : 0;
        final int uVal = uvIdx < uBytes.length ? uBytes[uvIdx] - 128 : 0;
        final int vVal = uvIdx < vBytes.length ? vBytes[uvIdx] - 128 : 0;

        // YUV to RGB conversion
        final int r = (yVal + (1.402 * vVal)).round().clamp(0, 255);
        final int g = (yVal - (0.344136 * uVal) - (0.714136 * vVal)).round().clamp(0, 255);
        final int b = (yVal + (1.772 * uVal)).round().clamp(0, 255);

        // YOLOv8 expects [0, 1] normalized RGB
        _inputBuffer[bufferIdx++] = r / 255.0;
        _inputBuffer[bufferIdx++] = g / 255.0;
        _inputBuffer[bufferIdx++] = b / 255.0;
      }
    }
  }
}
