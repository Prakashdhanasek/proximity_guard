// lib/core/monitoring_engine.dart
// Central pipeline — processes each camera frame through all 8 monitoring features

import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'monitor_state.dart';
import 'ear_calculator.dart';

class MonitoringEngine {
  static const double kEarVarianceThreshold = 0.005; // Stricter to avoid false sunglasses mode
  static const double kSunglassesEarHigh = 0.33;
  static const double kOneEyeEarLow = 0.10;
  static const double kDrowsySeconds = 1.0;
  static const double kAsleepSeconds = 2.0;
  static const double kBlinkResetSeconds = 0.5;
  static const double kYawThreshold = 20.0; // Stricter distraction threshold
  static const double kPitchThreshold = -10.0;
  static const double kDistractionSeconds = 1.5;
  static const double kHeadDropSeconds = 1.0;
  static const double kYawnMarThreshold = 0.60;
  static const double kYawnSeconds = 2.5;
  static const double kBlinkImpairmentDeviation = 0.50;
  static const double kImpairmentTriggerSeconds = 30.0;
  static const int kCalibrationFrames = 60; // 2 seconds at 30fps, better chance to catch a blink

  final MonitorState state;
  int _noEyeFrames = 0;

  MonitoringEngine(this.state);

  /// Main entry point — call once per frame with the detected face (if any)
  void processFrame(Face? face) {
    state.frameCount++;
    final now = DateTime.now();

    if (face == null) {
      _handleNoFace(now);
      return;
    }

    if (!state.calibrated) {
      _runCalibration(face, now);
      return;
    }

    _processHeadPose(face, now);
    _processEyesAndMouth(face, now);
    _processBlinks(now);
  }

  void _handleNoFace(DateTime now) {
    // If face disappears mid-session, pause drowsy timer
    state.eyesClosedSince = null;
    state.drowsinessLevel = DrowsinessLevel.alert;
    state.distractionStatus = DistractionStatus.forward;
    state.distractedSince = null;
  }

  // ─────────────────────────────────────────────
  // AUTO-CALIBRATION (first 40 frames)
  // ─────────────────────────────────────────────
  void _runCalibration(Face face, DateTime now) {
    final leftPts = EarCalculator.extractLeftEyePoints(face);
    final rightPts = EarCalculator.extractRightEyePoints(face);
    
    if (leftPts.isEmpty || rightPts.isEmpty) {
      _noEyeFrames++;
      if (_noEyeFrames >= 20) {
        // Auto-trigger sunglasses mode since eye landmarks are consistently missing
        state.monitorMode = MonitorMode.sunglasses;
        state.earBaseline = 0.28;
        state.earThreshold = 0.21;
        state.calibrated = true;
        state.blinkBaselineStart = now;
        print('[Monitoring] Sunglasses mode auto-detected during calibration (no eyes seen for 20 frames).');
      }
      return;
    }

    _noEyeFrames = 0; // Reset counter since eyes were successfully found
    state.calibrationFrame++;

    final leftEar = EarCalculator.calculateEar(leftPts);
    final rightEar = EarCalculator.calculateEar(rightPts);
    final avgEar = (leftEar + rightEar) / 2.0;
    state.calibrationEarValues.add(avgEar);

    if (state.calibrationFrame >= kCalibrationFrames) {
      _finalizeCalibration(leftEar, rightEar);
    }
  }

  void _finalizeCalibration(double lastLeft, double lastRight) {
    final vals = state.calibrationEarValues;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    final variance = vals.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / vals.length;

    // Check sunglasses: consistently high EAR with low variance
    if (avg > kSunglassesEarHigh && variance < kEarVarianceThreshold) {
      state.monitorMode = MonitorMode.sunglasses;
    }
    // Check one-eyed: one eye consistently below 0.10
    else if (lastLeft < kOneEyeEarLow) {
      state.monitorMode = MonitorMode.oneEye;
      state.oneEyeSide = 'RIGHT'; // using right eye
    } else if (lastRight < kOneEyeEarLow) {
      state.monitorMode = MonitorMode.oneEye;
      state.oneEyeSide = 'LEFT';
    } else {
      state.monitorMode = MonitorMode.normal;
    }

    // Set personal threshold = 80% of open-eye baseline
    state.earBaseline = avg;
    state.earThreshold = avg * 0.80;
    state.calibrated = true;

    // Start blink baseline period
    state.blinkBaselineStart = DateTime.now();
  }

  // ─────────────────────────────────────────────
  // HEAD POSE — Yaw (distraction) + Pitch (droop)
  // ─────────────────────────────────────────────
  void _processHeadPose(Face face, DateTime now) {
    // MLKit provides head euler angles directly — no solvePnP needed on mobile
    final yaw = face.headEulerAngleY ?? 0.0;    // left/right rotation
    final pitch = face.headEulerAngleX ?? 0.0;  // up/down tilt

    state.yaw = yaw;
    state.pitch = pitch;

    // Distraction: yaw > ±25° for 1.5s
    if (yaw.abs() > kYawThreshold) {
      state.distractedSince ??= now;
      final elapsed = now.difference(state.distractedSince!).inMilliseconds / 1000.0;
      if (elapsed >= kDistractionSeconds) {
        state.distractionStatus = DistractionStatus.distracted;
      }
    } else {
      state.distractedSince = null;
      state.distractionStatus = DistractionStatus.forward;
    }

    // Head droop: pitch < -15° for 1.5s (Applies to ALL modes, not just sunglasses!)
    if (pitch < kPitchThreshold) {
      state.headDropSince ??= now;
      final elapsed = now.difference(state.headDropSince!).inMilliseconds / 1000.0;
      if (elapsed >= kHeadDropSeconds) {
        state.drowsinessLevel = DrowsinessLevel.asleep; // Head droop is severe
        state.addAlert(AlertEvent(type: 'head_drop', message: 'WAKE UP – HEAD DROOPING!'));
      }
    } else {
      state.headDropSince = null;
      // Sunglasses reset: when pitch recovers, clear drowsiness/head droop alert
      if (state.monitorMode == MonitorMode.sunglasses && state.yawningSince == null) {
        state.drowsinessLevel = DrowsinessLevel.alert;
        state.eyesClosedSince = null;
      }
    }
  }

  // ─────────────────────────────────────────────
  // EAR + MAR PROCESSING
  // ─────────────────────────────────────────────
  void _processEyesAndMouth(Face face, DateTime now) {
    final leftPts = EarCalculator.extractLeftEyePoints(face);
    final rightPts = EarCalculator.extractRightEyePoints(face);

    double ear = 0.0;
    if (leftPts.isNotEmpty && rightPts.isNotEmpty) {
      final leftEar = EarCalculator.calculateEar(leftPts);
      final rightEar = EarCalculator.calculateEar(rightPts);
      state.leftEar = leftEar;
      state.rightEar = rightEar;

      switch (state.monitorMode) {
        case MonitorMode.normal:
          ear = (leftEar + rightEar) / 2.0;
          break;
        case MonitorMode.oneEye:
          ear = max(leftEar, rightEar);
          break;
        case MonitorMode.sunglasses:
          _processMar(face, now);
          return; // EAR not used in sunglasses mode
      }

      _processDrowsinessEar(ear, now);
    }
  }

  void _processDrowsinessEar(double ear, DateTime now) {
    final eyesClosed = ear < state.earThreshold;

    if (eyesClosed) {
      // Eyes closed — start or continue timer
      state.eyesClosedSince ??= now;
      state.eyesOpenSince = null;

      final closedSecs = now.difference(state.eyesClosedSince!).inMilliseconds / 1000.0;

      if (closedSecs >= kAsleepSeconds) {
        if (state.drowsinessLevel != DrowsinessLevel.asleep) {
          state.drowsinessLevel = DrowsinessLevel.asleep;
          state.addAlert(AlertEvent(type: 'asleep', message: 'ASLEEP AT THE WHEEL!'));
        }
      } else if (closedSecs >= kDrowsySeconds) {
        if (state.drowsinessLevel == DrowsinessLevel.alert) {
          state.drowsinessLevel = DrowsinessLevel.drowsy;
          state.addAlert(AlertEvent(type: 'drowsy', message: 'DROWSINESS DETECTED!'));
        }
      }
    } else {
      // Eyes open — blink-tolerant reset: must be open for 500ms to reset timer
      if (state.lastEyeStateOpen == false) {
        // Eye just opened — record blink end
        state.blinkTimestamps.add(now);
        state.eyesOpenSince = now;
      }

      if (state.eyesOpenSince != null) {
        final openSecs = now.difference(state.eyesOpenSince!).inMilliseconds / 1000.0;
        if (openSecs >= kBlinkResetSeconds) {
          state.eyesClosedSince = null;
          state.drowsinessLevel = DrowsinessLevel.alert;
        }
      }
    }

    state.lastEyeStateOpen = !eyesClosed;

    // Clean up blink timestamps older than 60s
    final cutoff = now.subtract(const Duration(seconds: 60));
    state.blinkTimestamps.removeWhere((t) => t.isBefore(cutoff));
  }

  void _processMar(Face face, DateTime now) {
    final mouthPts = EarCalculator.extractMouthPoints(face);
    if (mouthPts.isEmpty) return;

    final mar = EarCalculator.calculateMar(mouthPts);
    state.mar = mar;

    if (mar > kYawnMarThreshold) {
      state.yawningSince ??= now;
      final elapsed = now.difference(state.yawningSince!).inMilliseconds / 1000.0;
      if (elapsed >= kYawnSeconds) {
        if (state.drowsinessLevel == DrowsinessLevel.alert) {
          state.drowsinessLevel = DrowsinessLevel.drowsy;
          state.addAlert(AlertEvent(type: 'yawn', message: 'DROWSY – YAWNING DETECTED!'));
        }
      }
    } else {
      state.yawningSince = null;
    }
  }

  // ─────────────────────────────────────────────
  // BLINK RATE IMPAIRMENT DETECTION
  // ─────────────────────────────────────────────
  void _processBlinks(DateTime now) {
    // Phase 1: build baseline (first 60s after calibration)
    if (!state.blinkBaselineSet && state.blinkBaselineStart != null) {
      final elapsed = now.difference(state.blinkBaselineStart!).inSeconds;
      if (elapsed >= 60) {
        state.blinkBaseline = state.blinkTimestamps.length.toDouble();
        state.blinkBaselineSet = true;
        state.blinkTimestamps.clear();
      }
      return;
    }

    // Phase 2: ongoing monitoring
    if (!state.blinkBaselineSet || state.blinkBaseline < 1) return;

    // Check suppression
    if (state.impairmentSuppressedUntil != null &&
        now.isBefore(state.impairmentSuppressedUntil!)) return;

    final currentRate = state.blinkTimestamps.length.toDouble();
    final deviation = (currentRate - state.blinkBaseline).abs() / state.blinkBaseline;

    if (deviation >= kBlinkImpairmentDeviation) {
      state.impairmentFlaggedSince ??= now;
      final secs = now.difference(state.impairmentFlaggedSince!).inMilliseconds / 1000.0;
      if (secs >= kImpairmentTriggerSeconds && !state.impairmentFlag) {
        state.impairmentFlag = true;
        state.addAlert(AlertEvent(type: 'impairment', message: 'POSSIBLE IMPAIRMENT – REVIEW REQUIRED'));
      }
    } else {
      state.impairmentFlaggedSince = null;
    }
  }

  /// Called when supervisor presses C (clear impairment)
  void clearImpairmentFlag() {
    state.impairmentFlag = false;
    state.impairmentFlaggedSince = null;
    state.impairmentSuppressedUntil = DateTime.now().add(const Duration(minutes: 5));
  }
}
