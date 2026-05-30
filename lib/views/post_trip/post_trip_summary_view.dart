import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/views/live_route_map.dart';
import '../../controllers/trip_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/trip_summary_model.dart';
import '../../models/trip_alert_model.dart';
import '../theme/app_theme.dart';
import '../pre_trip/pre_trip_flow_view.dart';

class PostTripSummaryView extends StatelessWidget {
  const PostTripSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TripController>();
    final summary = controller.lastTripSummary;

    // Save to trip history
    if (summary != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SettingsController>().addTripToHistory(summary);
      });
    }

    if (summary == null) {
      return Scaffold(
        body: Center(
          child: Text('No trip data', style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.of(context).surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  children: [
                    _buildSafetyScoreCard(summary),
                    const SizedBox(height: 14),
                    _buildTripStatsCard(context, summary),
                    const SizedBox(height: 14),
                    _buildSafetyBreakdownCard(context, summary),
                    const SizedBox(height: 14),
                    _buildEventTimeline(context, summary),
                    const SizedBox(height: 14),
                    _buildIncidentReview(context, summary),
                    const SizedBox(height: 14),
                    _buildDrivingTrends(context),
                    const SizedBox(height: 20),
                    _buildDoneButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip Complete',
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Review your driving performance',
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Safety Score ───
  Widget _buildSafetyScoreCard(TripSummaryModel summary) {
    final score = summary.safetyScore;
    final color = _scoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Safety Score',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grade ${summary.scoreGrade}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Score ring
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _ScoreRingPainter(score: score / 100),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _scoreMessage(score),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.alerts.length} alerts · ${summary.criticalAlertCount} critical',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Trip Stats ───
  Widget _buildTripStatsCard(BuildContext context, TripSummaryModel summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Trip Summary', Icons.summarize_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile(context, Icons.timer_outlined, 'Duration', summary.formattedDuration, AppTheme.primary),
              const SizedBox(width: 10),
              _statTile(context, Icons.straighten_rounded, 'Distance', summary.formattedDistance, AppTheme.success),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statTile(context, Icons.speed_rounded, 'Avg Speed', '${summary.averageSpeed.toInt()} km/h', AppTheme.warning),
              const SizedBox(width: 10),
              _statTile(context, Icons.trending_up_rounded, 'Max Speed', '${summary.maxSpeed.toInt()} km/h',
                  summary.maxSpeed > summary.speedLimit ? AppTheme.danger : AppTheme.of(context).textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          LiveRouteMap(
  progress: 1.0,
  routeName: summary.routeName,
  incidents: summary.incidents.map((inc) {
    final total = summary.duration.inSeconds == 0 ? 1 : summary.duration.inSeconds;
    return MapIncident(
      progress: (inc.timestampInTrip.inSeconds / total).clamp(0.0, 1.0),
      color: inc.alert.severity == AlertSeverity.critical ? AppTheme.danger : AppTheme.warning,
    );
  }).toList(),
),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: AppTheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.routeName,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(BuildContext context, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Safety Breakdown ───
  Widget _buildSafetyBreakdownCard(BuildContext context, TripSummaryModel summary) {
    final b = summary.safetyBreakdown;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Safety Breakdown', Icons.shield_rounded),
          const SizedBox(height: 14),
          _breakdownRow(context, 'Following Distance', b.followingDistanceScore, Icons.social_distance_rounded),
          const SizedBox(height: 10),
          _breakdownRow(context, 'Speed Compliance', b.speedComplianceScore, Icons.speed_rounded),
          const SizedBox(height: 10),
          _breakdownRow(context, 'Alert Response', b.alertResponseScore, Icons.notifications_active_rounded),
          const SizedBox(height: 10),
          _breakdownRow(context, 'Attentiveness', b.attentivenessScore, Icons.visibility_rounded),
        ],
      ),
    );
  }

  Widget _breakdownRow(BuildContext context, String label, int score, IconData icon) {
    final color = _scoreColor(score);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$score%',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Event Timeline ───
  Widget _buildEventTimeline(BuildContext context, TripSummaryModel summary) {
    final allAlerts = summary.alerts;
    if (allAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            _sectionTitle(context, 'Event Timeline', Icons.timeline_rounded),
            const SizedBox(height: 20),
            Icon(Icons.check_circle_outline_rounded, size: 36, color: AppTheme.success.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text('No events!', style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    // Show max 6 items
    final displayAlerts = allAlerts.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(context, 'Event Timeline', Icons.timeline_rounded),
              const Spacer(),
              Text(
                '${allAlerts.length} events',
                style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...displayAlerts.asMap().entries.map((entry) {
            final i = entry.key;
            final alert = entry.value;
            final isLast = i == displayAlerts.length - 1;
            return _timelineItem(context, alert, isLast, summary.startTime);
          }),
          if (allAlerts.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+${allAlerts.length - 6} more events',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineItem(BuildContext context, TripAlertModel alert, bool isLast, DateTime tripStart) {
    final color = _alertSeverityColor(context, alert.severity);
    final offset = alert.timestamp.difference(tripStart);
    final m = offset.inMinutes;
    final s = offset.inSeconds.remainder(60);
    final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: GoogleFonts.poppins(
                            color: AppTheme.of(context).textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          alert.message,
                          style: GoogleFonts.poppins(
                            color: AppTheme.of(context).textMuted,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Incident Review ───
  Widget _buildIncidentReview(BuildContext context, TripSummaryModel summary) {
    final incidents = summary.incidents;
    if (incidents.isEmpty) {
      return const SizedBox.shrink();
    }

    final flagged = incidents.where((i) =>
        i.alert.severity == AlertSeverity.critical ||
        i.alert.severity == AlertSeverity.high).toList();

    if (flagged.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(context, 'Incident Review', Icons.warning_amber_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${flagged.length} flagged',
                  style: GoogleFonts.poppins(
                    color: AppTheme.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...flagged.take(5).map((incident) => _incidentTile(context, incident)),
        ],
      ),
    );
  }

  Widget _incidentTile(BuildContext context, TripIncident incident) {
    final color = _alertSeverityColor(context, incident.alert.severity);
    final icon = _alertTypeIcon(incident.alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.alert.title,
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  incident.alert.message,
                  style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                incident.formattedTimestamp,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (incident.hasVideo)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_rounded, color: AppTheme.primary, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      'Clip',
                      style: GoogleFonts.poppins(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Driving Trends ───
  Widget _buildDrivingTrends(BuildContext context) {
    final trends = context.read<TripController>().drivingTrends;

    // Generate mock weekly data if only 1 trip
    final displayTrends = trends.length < 3 ? _generateMockTrends(trends) : trends;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Driving Trends', Icons.trending_up_rounded),
          const SizedBox(height: 4),
          Text(
            'Last 7 trips',
            style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _TrendChartPainter(
                scores: displayTrends.map((t) => t.safetyScore).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _trendStat(context, 'Avg Score',
                  '${(displayTrends.map((t) => t.safetyScore).reduce((a, b) => a + b) / displayTrends.length).round()}'),
              _trendStat(context, 'Total Trips', '${displayTrends.length}'),
              _trendStat(context, 'Total Distance',
                  '${displayTrends.map((t) => t.distanceKm).reduce((a, b) => a + b).toStringAsFixed(1)} km'),
            ],
          ),
        ],
      ),
    );
  }

  List<DrivingTrend> _generateMockTrends(List<DrivingTrend> real) {
    final rng = math.Random(42);
    final now = DateTime.now();
    final mock = <DrivingTrend>[];
    for (int i = 6; i >= 1; i--) {
      mock.add(DrivingTrend(
        date: now.subtract(Duration(days: i)),
        safetyScore: 60 + rng.nextInt(35),
        distanceKm: 2.0 + rng.nextDouble() * 8,
        alertCount: rng.nextInt(8),
      ));
    }
    mock.addAll(real);
    return mock;
  }

  Widget _trendStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppTheme.of(context).textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 11),
        ),
      ],
    );
  }

  // ─── Done Button ───
  Widget _buildDoneButton(BuildContext context) {
    return AppTheme.gradientButton(
      label: 'Done',
      icon: Icons.check_rounded,
      onPressed: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PreTripFlowView()),
        );
      },
      height: 48,
    );
  }

  // ─── Helpers ───
  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppTheme.of(context).textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppTheme.of(context).card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.of(context).cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return AppTheme.primary;
    if (score >= 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  String _scoreMessage(int score) {
    if (score >= 90) return 'Excellent Driving!';
    if (score >= 80) return 'Great Job!';
    if (score >= 70) return 'Good, Room to Improve';
    if (score >= 50) return 'Needs Improvement';
    return 'Drive More Carefully';
  }

  Color _alertSeverityColor(BuildContext context, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => AppTheme.of(context).textMuted,
      AlertSeverity.medium => AppTheme.warning,
      AlertSeverity.high => const Color(0xFFEA580C),
      AlertSeverity.critical => AppTheme.danger,
    };
  }

  IconData _alertTypeIcon(AlertType type) {
    return switch (type) {
      AlertType.forwardDistance => Icons.social_distance_rounded,
      AlertType.drowsiness => Icons.bedtime_rounded,
      AlertType.distraction => Icons.phone_android_rounded,
      AlertType.geofenceBreach => Icons.location_off_rounded,
      AlertType.speedLimit => Icons.speed_rounded,
    };
  }
}

// ─── Score Ring Painter ───
class _ScoreRingPainter extends CustomPainter {
  final double score;
  _ScoreRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 7.0;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) => old.score != score;
}

// ─── Trend Chart Painter ───
class _TrendChartPainter extends CustomPainter {
  final List<int> scores;
  _TrendChartPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final padding = 8.0;
    final chartW = w - padding * 2;
    final chartH = h - padding * 2;
    final stepX = scores.length > 1 ? chartW / (scores.length - 1) : chartW;

    // Build points
    final points = <Offset>[];
    for (int i = 0; i < scores.length; i++) {
      final x = padding + i * stepX;
      final y = padding + chartH - (scores[i] / 100 * chartH);
      points.add(Offset(x, y));
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = padding + chartH * i / 4;
      canvas.drawLine(Offset(padding, y), Offset(w - padding, y), gridPaint);
    }

    // Fill
    if (points.length > 1) {
      final fillPath = Path()..moveTo(points.first.dx, h - padding);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, h - padding);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primary.withValues(alpha: 0.15),
            AppTheme.primary.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3, Paint()..color = AppTheme.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) => true;
}
