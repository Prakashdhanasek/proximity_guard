# ─────────────────────────────────────────────────────────────────────────────
# Proximity Guard — R8 / ProGuard keep rules
# Place this file at:  android/app/proguard-rules.pro
# ─────────────────────────────────────────────────────────────────────────────

# ── TensorFlow Lite (YOLOv8n + MobileFaceNet via tflite_flutter) ──
-keep class org.tensorflow.** { *; }
-keep interface org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# The GPU delegate is referenced even when unused (we run on CPU/XNNPACK).
# Without these, R8 fails on: org.tensorflow.lite.gpu.GpuDelegateFactory$Options
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-dontwarn org.tensorflow.lite.gpu.**

# ── Google ML Kit (face detection) ──
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ── Play Core (sometimes referenced by Flutter deferred components) ──
-dontwarn com.google.android.play.core.**