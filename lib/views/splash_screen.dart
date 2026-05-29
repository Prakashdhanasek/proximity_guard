import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../views/theme/app_theme.dart';
import 'pre_trip/pre_trip_flow_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _masterController;
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  late final AnimationController _particleController;

  // Phase 1: Background & particles fade in
  late final Animation<double> _bgGlowOpacity;
  // Phase 2: Shield entrance
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldOpacity;
  // Phase 3: Rings expand out
  late final Animation<double> _ringExpand;
  late final Animation<double> _ringOpacity;
  // Phase 4: Text
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _dividerWidth;
  // Phase 5: Bottom
  late final Animation<double> _bottomOpacity;
  // Continuous
  late final Animation<double> _pulseAnim;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _particleAnim;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    // --- Master timeline phases ---
    _bgGlowOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0, 0.2, curve: Curves.easeOut)),
    );

    _shieldScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.1, 0.4, curve: Curves.elasticOut)),
    );
    _shieldOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.1, 0.25, curve: Curves.easeOut)),
    );

    _ringExpand = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.25, 0.5, curve: Curves.easeOutCubic)),
    );
    _ringOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.25, 0.4, curve: Curves.easeOut)),
    );

    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.4, 0.6, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic)),
    );

    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.55, 0.75, curve: Curves.easeOut)),
    );
    _dividerWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.5, 0.7, curve: Curves.easeOutCubic)),
    );

    _bottomOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.7, 0.9, curve: Curves.easeOut)),
    );

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_rotateController);

    _particleAnim = Tween<double>(begin: 0, end: 1).animate(_particleController);

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _masterController.forward();
    _rotateController.repeat();
    _particleController.repeat();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PreTripFlowView(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _masterController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF050B18),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _masterController,
          _pulseController,
          _rotateController,
          _particleController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // Deep gradient background
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.3),
                    radius: 1.2,
                    colors: [
                      Color(0xFF0A1628),
                      Color(0xFF050B18),
                    ],
                  ),
                ),
              ),

              // Animated background glow behind shield
              Positioned(
                top: size.height * 0.22,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _bgGlowOpacity.value * 0.6,
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                          const Color(0xFF1D4ED8).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.4, 1],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating particles
              ...List.generate(18, (i) => _buildParticle(i, size)),

              // Rotating dashed orbit rings
              Center(
                child: Opacity(
                  opacity: _ringOpacity.value * 0.35,
                  child: Transform.rotate(
                    angle: _rotateAnim.value,
                    child: Transform.scale(
                      scale: 0.6 + (_ringExpand.value * 0.4),
                      child: CustomPaint(
                        size: const Size(280, 280),
                        painter: _OrbitRingPainter(
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Second orbit ring (counter-rotate)
              Center(
                child: Opacity(
                  opacity: _ringOpacity.value * 0.2,
                  child: Transform.rotate(
                    angle: -_rotateAnim.value * 0.6,
                    child: Transform.scale(
                      scale: 0.7 + (_ringExpand.value * 0.3),
                      child: CustomPaint(
                        size: const Size(340, 340),
                        painter: _OrbitRingPainter(
                          color: const Color(0xFF60A5FA),
                          dashCount: 40,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Main centered content
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Spacer(flex: 5),

                      // Shield logo with pulse glow
                      Opacity(
                        opacity: _shieldOpacity.value,
                        child: Transform.scale(
                          scale: _shieldScale.value,
                          child: _buildShieldLogo(),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Animated divider line
                      SizedBox(
                        width: 60 * _dividerWidth.value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF3B82F6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Title text
                      SlideTransition(
                        position: _titleSlide,
                        child: Opacity(
                          opacity: _titleOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'PROXIMITY',
                                style: GoogleFonts.rajdhani(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 12,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF818CF8)],
                                ).createShader(bounds),
                                child: Text(
                                  'GUARD',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 16,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Tagline / Drive badge
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                            ),
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'D R I V E',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF93C5FD),
                                  letterSpacing: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      // Bottom section — loading + version
                      Opacity(
                        opacity: _bottomOpacity.value,
                        child: Column(
                          children: [
                            // Custom animated dots loader
                            _buildDotsLoader(),
                            const SizedBox(height: 20),
                            Text(
                              'Initializing secure connection...',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'v1.0.0',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShieldLogo() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing glow
          Transform.scale(
            scale: _pulseAnim.value * 1.2,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    const Color(0xFF3B82F6).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6, 1],
                ),
              ),
            ),
          ),

          // Outer hexagonal-feel ring
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
          ),

          // Middle ring with gradient
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
          ),

          // Inner glowing circle
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment(-0.8, -1),
                end: Alignment(0.8, 1),
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF1D4ED8),
                  Color(0xFF1E40AF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                  blurRadius: 80,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),

          // Glass-like inner highlight
          Positioned(
            top: 38,
            child: Container(
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Custom painted shield icon
          CustomPaint(
            size: const Size(52, 58),
            painter: _ShieldIconPainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index, Size screenSize) {
    final random = math.Random(index * 42);
    final startX = random.nextDouble() * screenSize.width;
    final startY = random.nextDouble() * screenSize.height;
    final drift = 20.0 + random.nextDouble() * 40;
    final particleSize = 1.5 + random.nextDouble() * 2.5;
    final phase = random.nextDouble();
    final speed = 0.3 + random.nextDouble() * 0.7;

    final progress = ((_particleAnim.value * speed) + phase) % 1.0;
    final yOffset = -drift * progress;
    final opacity = math.sin(progress * math.pi) * (0.3 + random.nextDouble() * 0.4);

    return Positioned(
      left: startX + math.sin(progress * math.pi * 2) * 10,
      top: startY + yOffset,
      child: Opacity(
        opacity: (_bgGlowOpacity.value * opacity).clamp(0.0, 1.0),
        child: Container(
          width: particleSize,
          height: particleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index % 3 == 0
                ? const Color(0xFF60A5FA)
                : index % 3 == 1
                    ? const Color(0xFF818CF8)
                    : const Color(0xFF93C5FD),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotsLoader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.18;
        final t = ((_particleAnim.value * 3 + delay) % 1.0);
        final scale = 0.6 + 0.4 * math.sin(t * math.pi);
        final opacity = 0.3 + 0.7 * math.sin(t * math.pi);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Custom painter for dashed orbit rings
class _OrbitRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;

  _OrbitRingPainter({required this.color, this.dashCount = 60});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashFraction = 0.4;
    final dashArc = (2 * math.pi / dashCount) * dashFraction;
    final gapArc = (2 * math.pi / dashCount) * (1 - dashFraction);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashArc + gapArc);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashArc,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the shield icon with a modern vector look
class _ShieldIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shield outline
    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..quadraticBezierTo(w * 0.05, h * 0.08, w * 0.08, h * 0.38)
      ..quadraticBezierTo(w * 0.1, h * 0.68, w * 0.5, h)
      ..quadraticBezierTo(w * 0.9, h * 0.68, w * 0.92, h * 0.38)
      ..quadraticBezierTo(w * 0.95, h * 0.08, w * 0.5, 0)
      ..close();

    // Shield fill — semi transparent white
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, fillPaint);

    // Shield border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(shieldPath, borderPaint);

    // Checkmark inside
    final checkPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(w * 0.28, h * 0.48)
      ..lineTo(w * 0.44, h * 0.64)
      ..lineTo(w * 0.72, h * 0.32);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
