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
  // Increased to 0.55 to avoid false positives (like hands or seatbelts being detected as Cell Phones)
  static const double kConfidenceThreshold = 0.55;
  // Tweaked to 0.25 (sweet spot) for bottles and glasses
  static const double kFoodConfidenceThreshold = 0.25;
  // IoU overlap threshold for NMS
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
      _convertYUV420ToYOLOInput(image, rotation);
      _interpreter!.getInputTensor(0).data = _inputBuffer.buffer.asUint8List();
      _interpreter!.invoke();

      final outputFloatView = Float32List.sublistView(_interpreter!.getOutputTensor(0).data);
      final rawDetections = _parseDetections(outputFloatView);
      final nmsResults = _applyNMS(rawDetections);

      final uniqueObjects = <String, DetectedObject>{};
      for (final obj in nmsResults) {
        if (!uniqueObjects.containsKey(obj.label) || obj.confidence > uniqueObjects[obj.label]!.confidence) {
          uniqueObjects[obj.label] = obj;
        }
      }

      state.detectedObjects = uniqueObjects.values.toList();

      bool seatbeltFoundInFrame = false;

      // Extract seatbelt detection from YOLO and remove it so it doesn't show up in UI
      state.detectedObjects.removeWhere((obj) {
        if (obj.label == 'Seatbelt') {
          seatbeltFoundInFrame = true;
          return true;
        }
        return false;
      });

      for (final obj in state.detectedObjects) {
        if (obj.label == 'Cell Phone') {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'FLAG: BANNED OBJECT: CELL PHONE',
            needsScreenshot: true,
            isMajorFlag: true,
          ));
        } else if (obj.label == 'Drink') {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'FLAG: BANNED DRINK',
            needsScreenshot: true,
            isMajorFlag: true,
          ));
        } else if (obj.label == 'Cigarette' || obj.label == 'Vape') {
          state.addAlert(AlertEvent(
            type: 'banned_object',
            message: 'FLAG: SMOKING/VAPING DETECTED',
            needsScreenshot: true,
            isMajorFlag: true,
          ));
        }
      }

      // Automatic seatbelt tracking (grace period of 5 seconds to prevent flickering)
      if (seatbeltFoundInFrame) {
        state.seatbeltBuckled = true;
        state.lastSeatbeltDetected = DateTime.now();
      } else if (state.lastSeatbeltDetected != null) {
        final elapsed = DateTime.now().difference(state.lastSeatbeltDetected!).inMilliseconds / 1000.0;
        if (elapsed > 5.0) {
          state.seatbeltBuckled = false;
        }
      }
    } catch (e) {
      print('[YOLO] Inference error: $e');
    }
  }

  // Target COCO classes:
  // 39=bottle, 41=cup, 46=wine glass -> 'Drink'
  // 67=cell phone -> 'Cell Phone'
  static const Map<int, String> _targets = {
    39: 'Drink',
    41: 'Drink',
    46: 'Drink',
    67: 'Cell Phone',
    24: 'Seatbelt',
    27: 'Seatbelt',
    43: 'Cigarette',
    44: 'Cigarette',
    45: 'Cigarette',
    79: 'Cigarette',
  };

  List<DetectedObject> _parseDetections(Float32List output) {
    const int numBoxes = 8400;
    final List<DetectedObject> found = [];

    for (int col = 0; col < numBoxes; col++) {
      double maxProb = 0.0;
      int bestClass = -1;

      for (int cls = 0; cls < 80; cls++) {
        final prob = output[(4 + cls) * numBoxes + col];
        if (prob > maxProb) {
          maxProb = prob;
          bestClass = cls;
        }
      }

      if (maxProb >= kFoodConfidenceThreshold && _targets.containsKey(bestClass)) {
        final cx = output[col] / 640.0;
        final cy = output[numBoxes + col] / 640.0;
        final w = output[2 * numBoxes + col] / 640.0;
        final h = output[3 * numBoxes + col] / 640.0;
        
        String label = _targets[bestClass]!;

        if (label == 'Cell Phone') {
          if (maxProb < 0.45) continue; // Lowered to fix false negatives, high enough to avoid hands
        } else if (label == 'Seatbelt') {
          if (maxProb < 0.05) continue; // Must be sensitive since YOLO uses 'tie/backpack' as proxy
          if (cy < 0.30) continue; // Seatbelt must be in the chest/lower body area, not the ceiling
        } else if (label == 'Drink') {
          if (maxProb < 0.20) continue; // Lowered to catch cups/bottles easily
        } else if (label == 'Cigarette') {
          if (maxProb < 0.15) continue; // Uses spoon/fork proxy, needs low threshold
          // Strictly restrict to the mouth/lower face region to prevent false positives from background
          if (cy < 0.30 || cy > 0.85 || cx < 0.20 || cx > 0.80) continue;
        } else if (maxProb < 0.45) {
          continue;
        }

        // SIZE HEURISTIC: Reject cell phones that are massive (likely wall/screen background)
        if (label == 'Cell Phone' && h > 0.70) {
          continue;
        }

        found.add(DetectedObject(
          label: label,
          confidence: maxProb,
          x: cx - w / 2,
          y: cy - h / 2,
          width: w,
          height: h,
        ));
      }
    }

    // ── Pixel Heuristics: Seatbelt via diagonal edge pair detector ──────
    _applyPixelHeuristics(found);

    return found;
  }

  // Scans for the seatbelt: a uniform-colour diagonal strap with contrast on both edges.
  // The COCO YOLO model has no seatbelt class, so we must do this in pixel space.
  void _applyPixelHeuristics(List<DetectedObject> found) {
    // Only run if no seatbelt already detected by YOLO
    if (found.any((o) => o.label == 'Seatbelt')) return;

    // The seatbelt runs diagonally from shoulder to chest.
    // We test two paths: Path A = left-hand drive (left shoulder → right chest)
    //                    Path B = right-hand drive (right shoulder → left chest)
    // At each of 7 sample points we check:
    //   (a) The belt pixel has meaningful contrast against BOTH the left and right neighbor (double-edge)
    //   (b) The belt pixel color is similar to adjacent belt pixels (uniform strap color)
    const List<List<List<int>>> paths = [
      [[80,195],[115,240],[150,285],[190,335],[230,385],[275,435],[320,475]],  // Path A: left→right
      [[555,195],[520,240],[485,285],[445,335],[405,385],[360,435],[315,475]], // Path B: right→left
    ];

    for (final path in paths) {
      int edgeHits = 0;
      double prevGray = -1;
      int colorConsistency = 0;

      for (final pt in path) {
        final bx = pt[0]; final by = pt[1];
        final beltGray = _getGray(bx, by);

        // Check double-edge: belt must contrast against BOTH left and right neighbours
        final leftGray  = _getGray(bx - 22, by);
        final rightGray = _getGray(bx + 22, by);
        final contrastL = (beltGray - leftGray).abs();
        final contrastR = (beltGray - rightGray).abs();
        if (contrastL > 0.08 && contrastR > 0.08) edgeHits++;

        // Check color consistency: adjacent belt pixels should be similar
        if (prevGray >= 0 && (beltGray - prevGray).abs() < 0.12) colorConsistency++;
        prevGray = beltGray;
      }

      // Need 4/7 double-edge hits AND 4/6 color-consistent steps
      if (edgeHits >= 4 && colorConsistency >= 4) {
        found.add(DetectedObject(label: 'Seatbelt', confidence: 0.92, x: 0.1, y: 0.3, width: 0.5, height: 0.5));
        return; // Found on first matching path
      }
    }
  }

  double _getGray(int x, int y) {
    if (x < 0 || x >= 640 || y < 0 || y >= 640) return 0.0;
    final int idx = (y * 640 + x) * 3;
    if (idx + 2 >= _inputBuffer.length) return 0.0;
    return _inputBuffer[idx] * 0.299 + _inputBuffer[idx+1] * 0.587 + _inputBuffer[idx+2] * 0.114;
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
