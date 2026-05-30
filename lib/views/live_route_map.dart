import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proximity_guard/views/theme/app_theme.dart';

/// ============================================================================
/// LiveRouteMap
/// ----------------------------------------------------------------------------
/// A self-contained, dependency-free route map for Proximity Guard Drive.
///
/// WHY THIS EXISTS:
///   The blueprint requires a "Live map / route traces / GPS" view (Maps = P0,
///   mobile location = P1). The project previously visualised the route only as
///   a 10-segment progress bar and stored no coordinates. This widget renders
///   an actual map: a route polyline, a moving vehicle marker (with heading),
///   start/destination pins, an operating geofence zone, and incident markers.
///
///   It is driven by the SAME data you already have (`routeProgress` 0..1 from
///   TripController), so it works in the simulated pilot demo with ZERO new
///   packages, ZERO API keys and ZERO native setup.
///
/// HOW TO USE (live HUD, during_trip/driving_hud_view.dart):
///   Replace the route-progress card with:
///
///     LiveRouteMap(
///       progress: data.routeProgress,
///       routeName: data.routeName,
///       isLive: true,
///       inGeofence: data.isInGeofence,
///       speedKmh: data.currentSpeed,
///     )
///
/// HOW TO USE (post-trip, post_trip_summary_view.dart):
///   Build incident markers from the trip's incidents, then:
///
///     LiveRouteMap(
///       progress: 1.0,
///       routeName: summary.routeName,
///       isLive: false,
///       incidents: summary.incidents.map((inc) {
///         final total = summary.duration.inSeconds == 0
///             ? 1
///             : summary.duration.inSeconds;
///         return MapIncident(
///           progress: (inc.timestampInTrip.inSeconds / total).clamp(0.0, 1.0),
///           color: inc.alert.severity == AlertSeverity.critical
///               ? AppTheme.danger
///               : AppTheme.warning,
///         );
///       }).toList(),
///     )
///
/// UPGRADING TO REAL GPS LATER (optional, production):
///   1. Add to pubspec.yaml:  flutter_map: ^7.0.0   latlong2: ^0.9.1
///      and geolocator: ^13.0.0 for live device position.
///   2. Feed real LatLng points into a flutter_map Polyline; keep this widget
///      as the offline / no-signal fallback. The public API here (progress +
///      incidents) maps cleanly onto a real polyline.
/// ============================================================================

/// A point of interest plotted along the route, expressed as a fraction of the
/// total route length (0.0 = start, 1.0 = destination).
class MapIncident {
  final double progress;
  final Color color;
  final IconData icon;

  const MapIncident({
    required this.progress,
    required this.color,
    this.icon = Icons.warning_amber_rounded,
  });
}

class LiveRouteMap extends StatefulWidget {
  /// 0.0 .. 1.0 — how far along the route the vehicle is.
  final double progress;

  /// Optional human-readable route label shown in the bottom chip.
  final String? routeName;

  /// When true, shows a pulsing "LIVE" badge and animates the vehicle marker.
  final bool isLive;

  /// When false, the geofence outline turns to a warning colour.
  final bool inGeofence;

  /// Optional speed read-out shown on the live badge.
  final double? speedKmh;

  /// Optional incident pins along the route (e.g. drowsiness / harsh events).
  final List<MapIncident> incidents;

  /// Draw the operating-zone (geofence) outline.
  final bool showGeofence;

  /// Map height. Defaults to a compact card size.
  final double height;

  /// Normalised route polyline (each Offset in the 0..1 unit square, y down).
  /// Defaults to a built-in demo route so it works out of the box.
  final List<Offset>? routePoints;

  const LiveRouteMap({
    super.key,
    required this.progress,
    this.routeName,
    this.isLive = false,
    this.inGeofence = true,
    this.speedKmh,
    this.incidents = const [],
    this.showGeofence = true,
    this.height = 220,
    this.routePoints,
  });

  /// A pleasant winding demo route in normalised (0..1) space.
  static const List<Offset> demoRoute = [
    Offset(0.10, 0.82),
    Offset(0.22, 0.70),
    Offset(0.20, 0.50),
    Offset(0.36, 0.42),
    Offset(0.50, 0.52),
    Offset(0.62, 0.40),
    Offset(0.60, 0.22),
    Offset(0.78, 0.20),
    Offset(0.90, 0.30),
  ];

  @override
  State<LiveRouteMap> createState() => _LiveRouteMapState();
}

class _LiveRouteMapState extends State<LiveRouteMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late double _shownProgress;

  @override
  void initState() {
    super.initState();
    _shownProgress = widget.progress.clamp(0.0, 1.0);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant LiveRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Smoothly catch up to the new progress value on the next frame.
    _shownProgress = widget.progress.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.of(context);
    final points = widget.routePoints ?? LiveRouteMap.demoRoute;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // The map itself.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _shownProgress),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, animatedProgress, _) {
                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, __) {
                      return CustomPaint(
                        painter: _RouteMapPainter(
                          points: points,
                          progress: animatedProgress,
                          pulse: _pulse.value,
                          isLive: widget.isLive,
                          inGeofence: widget.inGeofence,
                          showGeofence: widget.showGeofence,
                          incidents: widget.incidents,
                          isDark: colors.isDark,
                          primary: AppTheme.primary,
                          warning: AppTheme.warning,
                          danger: AppTheme.danger,
                          success: AppTheme.success,
                          gridColor: colors.cardBorder,
                          surfaceColor: colors.surface,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // LIVE badge (top-left).
            if (widget.isLive)
              Positioned(
                left: 12,
                top: 12,
                child: _LiveBadge(
                  pulse: _pulse,
                  speedKmh: widget.speedKmh,
                ),
              ),

            // Compass (top-right).
            Positioned(
              right: 12,
              top: 12,
              child: _Compass(color: colors.textSecondary, bg: colors.card),
            ),

            // Geofence status chip (bottom-left).
            if (widget.showGeofence)
              Positioned(
                left: 12,
                bottom: 12,
                child: _Chip(
                  icon: widget.inGeofence
                      ? Icons.shield_rounded
                      : Icons.location_off_rounded,
                  label: widget.inGeofence ? 'In zone' : 'Zone breach',
                  color: widget.inGeofence ? AppTheme.success : AppTheme.danger,
                  bg: colors.card,
                ),
              ),

            // Route name chip (bottom-right).
            if (widget.routeName != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: _Chip(
                    icon: Icons.route_rounded,
                    label: widget.routeName!,
                    color: AppTheme.primary,
                    bg: colors.card,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// Painter
/// ============================================================================
class _RouteMapPainter extends CustomPainter {
  final List<Offset> points;
  final double progress; // 0..1
  final double pulse; // 0..1 animation phase
  final bool isLive;
  final bool inGeofence;
  final bool showGeofence;
  final List<MapIncident> incidents;
  final bool isDark;
  final Color primary;
  final Color warning;
  final Color danger;
  final Color success;
  final Color gridColor;
  final Color surfaceColor;

  _RouteMapPainter({
    required this.points,
    required this.progress,
    required this.pulse,
    required this.isLive,
    required this.inGeofence,
    required this.showGeofence,
    required this.incidents,
    required this.isDark,
    required this.primary,
    required this.warning,
    required this.danger,
    required this.success,
    required this.gridColor,
    required this.surfaceColor,
  });

  static const double _pad = 18;

  Offset _toCanvas(Offset n, Size s) => Offset(
        _pad + n.dx * (s.width - 2 * _pad),
        _pad + n.dy * (s.height - 2 * _pad),
      );

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintStreetGrid(canvas, size);
    if (showGeofence) _paintGeofence(canvas, size);

    final routePath = _buildSmoothPath(
      points.map((p) => _toCanvas(p, size)).toList(),
    );

    final metrics = routePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final totalLen = metric.length;
    final travelledLen = (totalLen * progress).clamp(0.0, totalLen);

    // Remaining route (faint, dashed).
    _drawDashedPath(
      canvas,
      metric.extractPath(travelledLen, totalLen),
      Paint()
        ..color = primary.withValues(alpha: 0.25)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
      dash: 10,
      gap: 8,
    );

    // Travelled route (solid, glowing).
    final travelled = metric.extractPath(0, travelledLen);
    canvas.drawPath(
      travelled,
      Paint()
        ..color = primary.withValues(alpha: 0.25)
        ..strokeWidth = 11
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      travelled,
      Paint()
        ..color = primary
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Start + destination pins.
    final start = metric.getTangentForOffset(0)!.position;
    final end = metric.getTangentForOffset(totalLen)!.position;
    _drawStartPin(canvas, start);
    _drawDestinationPin(canvas, end);

    // Incident markers.
    for (final inc in incidents) {
      final t = metric.getTangentForOffset(
        (totalLen * inc.progress).clamp(0.0, totalLen),
      );
      if (t != null) _drawIncident(canvas, t.position, inc);
    }

    // Vehicle marker (skip if exactly at the destination on a finished trip).
    final vt = metric.getTangentForOffset(travelledLen);
    if (vt != null) _drawVehicle(canvas, vt.position, vt.angle);
  }

  // ---- layers ---------------------------------------------------------------

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF111B2E), const Color(0xFF0C1525)]
              : [const Color(0xFFEFF4FB), const Color(0xFFE7EEF7)],
        ).createShader(rect),
    );

    // A soft "park / green space" blob for map texture.
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.72),
      size.height * 0.28,
      Paint()
        ..color = success.withValues(alpha: isDark ? 0.10 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _paintStreetGrid(Canvas canvas, Size size) {
    final p = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.35 : 0.55)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    // A couple of "main roads" for character.
    final road = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.6 : 0.9)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(0, size.height * 0.34),
      Offset(size.width, size.height * 0.30),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, 0),
      Offset(size.width * 0.50, size.height),
      road,
    );
  }

  void _paintGeofence(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(18),
    );
    final zoneColor = inGeofence ? primary : danger;
    canvas.drawRRect(
      rrect,
      Paint()..color = zoneColor.withValues(alpha: 0.05),
    );
    _drawDashedPath(
      canvas,
      Path()..addRRect(rrect),
      Paint()
        ..color = zoneColor.withValues(alpha: 0.55)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      dash: 7,
      gap: 6,
    );
  }

  // ---- markers --------------------------------------------------------------

  void _drawStartPin(Canvas canvas, Offset c) {
    canvas.drawCircle(c, 9, Paint()..color = Colors.white);
    canvas.drawCircle(c, 9, Paint()..color = success.withValues(alpha: 0.18));
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..color = success
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(c, 3.5, Paint()..color = success);
  }

  void _drawDestinationPin(Canvas canvas, Offset c) {
    // Teardrop pin.
    final pinTop = Offset(c.dx, c.dy - 26);
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(c.dx - 11, c.dy - 16, pinTop.dx - 8, pinTop.dy + 6)
      ..arcToPoint(Offset(pinTop.dx + 8, pinTop.dy + 6),
          radius: const Radius.circular(9))
      ..quadraticBezierTo(c.dx + 11, c.dy - 16, c.dx, c.dy)
      ..close();
    canvas.drawShadow(path, Colors.black, 3, true);
    canvas.drawPath(path, Paint()..color = danger);
    canvas.drawCircle(
      Offset(pinTop.dx, pinTop.dy + 6),
      4.5,
      Paint()..color = Colors.white,
    );
  }

  void _drawIncident(Canvas canvas, Offset c, MapIncident inc) {
    canvas.drawCircle(c, 8, Paint()..color = Colors.white);
    canvas.drawCircle(c, 8, Paint()..color = inc.color);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(inc.icon.codePoint),
        style: TextStyle(
          fontFamily: inc.icon.fontFamily,
          package: inc.icon.fontPackage,
          fontSize: 10,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawVehicle(Canvas canvas, Offset c, double angle) {
    // Pulsing halo (live only).
    if (isLive) {
      final r = 14 + pulse * 14;
      canvas.drawCircle(
        c,
        r,
        Paint()..color = primary.withValues(alpha: (1 - pulse) * 0.35),
      );
    }
    // White ring base.
    canvas.drawCircle(c, 11, Paint()..color = Colors.white);
    canvas.drawCircle(c, 11, Paint()..color = primary);

    // Heading chevron.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final chevron = Path()
      ..moveTo(6, 0)
      ..lineTo(-3, -4.5)
      ..lineTo(-1, 0)
      ..lineTo(-3, 4.5)
      ..close();
    canvas.drawPath(chevron, Paint()..color = Colors.white);
    canvas.restore();
  }

  // ---- geometry helpers -----------------------------------------------------

  /// Catmull-Rom -> cubic Bézier smoothing through [pts].
  Path _buildSmoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length < 3) {
      path.moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final m in source.computeMetrics()) {
      double dist = 0;
      while (dist < m.length) {
        final next = math.min(dist + dash, m.length);
        canvas.drawPath(m.extractPath(dist, next), paint);
        dist = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMapPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.inGeofence != inGeofence ||
      old.incidents != incidents ||
      old.isDark != isDark;
}

/// ============================================================================
/// Overlay chrome widgets
/// ============================================================================
class _LiveBadge extends StatelessWidget {
  final AnimationController pulse;
  final double? speedKmh;
  const _LiveBadge({required this.pulse, this.speedKmh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween(begin: 0.3, end: 1.0).animate(pulse),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (speedKmh != null) ...[
            const SizedBox(width: 8),
            Text(
              '${speedKmh!.toInt()} km/h',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Compass extends StatelessWidget {
  final Color color;
  final Color bg;
  const _Compass({required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.navigation_rounded, size: 13, color: AppTheme.danger),
          Text(
            'N',
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}