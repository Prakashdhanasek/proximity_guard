import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/views/live_route_map.dart';
import 'package:proximity_guard/views/theme/app_assets.dart';

import '../../controllers/trip_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../models/trip_summary_model.dart';
import '../../models/trip_alert_model.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../pre_trip/pre_trip_flow_view.dart';

class PostTripSummaryView extends StatelessWidget {
  const PostTripSummaryView({super.key});

  static const Color _primaryBlue = Color(0xFF2563FF);
  static const Color _primaryBlueDark = Color(0xFF1D4ED8);
  static const Color _screenBg = Color(0xFFF8FAFC);
  static const Color _softBorder = Color(0xFFE5EAF2);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final controller = context.read<TripController>();
    final summary = controller.lastTripSummary;

    if (summary != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SettingsController>().addTripToHistory(summary);
      });
    }

    if (summary == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: _primaryBlue,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: _screenBg,
          body: Center(
            child: Text(
              l.noTripData,
              style: GoogleFonts.poppins(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _primaryBlue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _screenBg,
        body: Column(
          children: [
            _buildTopAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                child: Column(
                  children: [
                    _buildSafetyScoreCard(context, summary),
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

  // ─── Localized alert title/message from type ───
  String _alertTitle(AppLocalizations l, AlertType type) {
    switch (type) {
      case AlertType.forwardDistance:
        return l.alertFollowingTitle;
      case AlertType.drowsiness:
        return l.alertDrowsyTitle;
      case AlertType.distraction:
        return l.alertDistractionTitle;
      case AlertType.geofenceBreach:
        return l.alertGeofenceTitle;
      case AlertType.speedLimit:
        return l.alertSpeedTitle;
    }
  }

  String _alertMsg(AppLocalizations l, AlertType type) {
    switch (type) {
      case AlertType.forwardDistance:
        return l.alertFollowingMsg;
      case AlertType.drowsiness:
        return l.alertDrowsyMsg;
      case AlertType.distraction:
        return l.alertDistractionMsg;
      case AlertType.geofenceBreach:
        return l.alertGeofenceMsg;
      case AlertType.speedLimit:
        return l.alertSpeedMsg;
    }
  }

  // ─── Top App Bar Like Previous Screen ───
  Widget _buildTopAppBar(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      // height: 140,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.appbar),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PreTripFlowView()),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tripComplete,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l.reviewPerformance,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  l.done,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Safety Score ───
  Widget _buildSafetyScoreCard(BuildContext context, TripSummaryModel summary) {
    final l = AppLocalizations.of(context);
    final score = summary.safetyScore;
    final color = _scoreColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _sectionTitle(context, l.safetyScoreLabel, Icons.shield_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${l.gradeLabel} ${summary.scoreGrade}',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 128,
            height: 128,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                score: score / 100,
                color: color,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: GoogleFonts.poppins(
                        color: _textDark,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: GoogleFonts.poppins(
                        color: _textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _scoreMessage(l, score),
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${summary.alerts.length} ${l.alerts} · ${summary.criticalAlertCount} ${l.criticalWord}',
            style: GoogleFonts.poppins(
              color: _textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Trip Stats ───
  Widget _buildTripStatsCard(BuildContext context, TripSummaryModel summary) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, l.tripSummary, Icons.summarize_rounded),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile(
                context,
                Icons.timer_outlined,
                l.duration,
                summary.formattedDuration,
                _primaryBlue,
              ),
              const SizedBox(width: 10),
              _statTile(
                context,
                Icons.straighten_rounded,
                l.distance,
                summary.formattedDistance,
                AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statTile(
                context,
                Icons.speed_rounded,
                l.avgSpeed,
                '${summary.averageSpeed.toInt()} km/h',
                AppTheme.warning,
              ),
              const SizedBox(width: 10),
              _statTile(
                context,
                Icons.trending_up_rounded,
                l.maxSpeed,
                '${summary.maxSpeed.toInt()} km/h',
                summary.maxSpeed > summary.speedLimit
                    ? AppTheme.danger
                    : _textMuted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LiveRouteMap(
              progress: 1.0,
              routeName: summary.routeName,
              incidents: summary.incidents.map((inc) {
                final total = summary.duration.inSeconds == 0
                    ? 1
                    : summary.duration.inSeconds;

                return MapIncident(
                  progress:
                      (inc.timestampInTrip.inSeconds / total).clamp(0.0, 1.0),
                  color: inc.alert.severity == AlertSeverity.critical
                      ? AppTheme.danger
                      : AppTheme.warning,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryBlue.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: _primaryBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary.routeName,
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
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

  Widget _statTile(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: _textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
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
  Widget _buildSafetyBreakdownCard(
    BuildContext context,
    TripSummaryModel summary,
  ) {
    final l = AppLocalizations.of(context);
    final b = summary.safetyBreakdown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, l.safetyBreakdown, Icons.shield_rounded),
          const SizedBox(height: 14),
          _breakdownRow(
            context,
            l.followingDistance,
            b.followingDistanceScore,
            Icons.social_distance_rounded,
          ),
          const SizedBox(height: 12),
          _breakdownRow(
            context,
            l.speedCompliance,
            b.speedComplianceScore,
            Icons.speed_rounded,
          ),
          const SizedBox(height: 12),
          _breakdownRow(
            context,
            l.alertResponse,
            b.alertResponseScore,
            Icons.notifications_active_rounded,
          ),
          const SizedBox(height: 12),
          _breakdownRow(
            context,
            l.attentiveness,
            b.attentivenessScore,
            Icons.visibility_rounded,
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    BuildContext context,
    String label,
    int score,
    IconData icon,
  ) {
    final color = _scoreColor(score);

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: _textDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$score%',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: score / 100,
                  backgroundColor: const Color(0xFFEAF0F7),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
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
    final l = AppLocalizations.of(context);
    final allAlerts = summary.alerts;

    if (allAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            _sectionTitle(context, l.eventTimeline, Icons.timeline_rounded),
            const SizedBox(height: 20),
            Icon(
              Icons.check_circle_outline_rounded,
              size: 38,
              color: AppTheme.success.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 8),
            Text(
              l.noEvents,
              style: GoogleFonts.poppins(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final displayAlerts = allAlerts.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle(context, l.eventTimeline, Icons.timeline_rounded),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${allAlerts.length} ${l.eventsWord}',
                  style: GoogleFonts.poppins(
                    color: _primaryBlue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                  '+${allAlerts.length - 6} ${l.moreEventsWord}',
                  style: GoogleFonts.poppins(
                    color: _primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    BuildContext context,
    TripAlertModel alert,
    bool isLast,
    DateTime tripStart,
  ) {
    final l = AppLocalizations.of(context);
    final color = _alertSeverityColor(context, alert.severity);
    final offset = alert.timestamp.difference(tripStart);
    final m = offset.inMinutes;
    final s = offset.inSeconds.remainder(60);
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.4,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _softBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _alertTitle(l, alert.type),
                            style: GoogleFonts.poppins(
                              color: _textDark,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _alertMsg(l, alert.type),
                            style: GoogleFonts.poppins(
                              color: _textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      color: _textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
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
    final l = AppLocalizations.of(context);
    final incidents = summary.incidents;

    if (incidents.isEmpty) {
      return const SizedBox.shrink();
    }

    final flagged = incidents
        .where(
          (i) =>
              i.alert.severity == AlertSeverity.critical ||
              i.alert.severity == AlertSeverity.high,
        )
        .toList();

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
              _sectionTitle(
                context,
                l.incidentReview,
                Icons.warning_amber_rounded,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${flagged.length} ${l.flaggedWord}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.danger,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
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
    final l = AppLocalizations.of(context);
    final color = _alertSeverityColor(context, incident.alert.severity);
    final icon = _alertTypeIcon(incident.alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alertTitle(l, incident.alert.type),
                  style: GoogleFonts.poppins(
                    color: _textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _alertMsg(l, incident.alert.type),
                  style: GoogleFonts.poppins(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
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
                  color: _textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (incident.hasVideo)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: _primaryBlue,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      l.clip,
                      style: GoogleFonts.poppins(
                        color: _primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
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
    final l = AppLocalizations.of(context);
    final trends = context.read<TripController>().drivingTrends;

    final displayTrends = trends.length < 3
        ? _generateMockTrends(trends)
        : trends;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, l.drivingTrends, Icons.trending_up_rounded),
          const SizedBox(height: 4),
          Text(
            l.last7Trips,
            style: GoogleFonts.poppins(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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
              _trendStat(
                context,
                l.avgScoreLabel,
                '${(displayTrends.map((t) => t.safetyScore).reduce((a, b) => a + b) / displayTrends.length).round()}',
              ),
              _trendStat(
                context,
                l.totalTripsLabel,
                '${displayTrends.length}',
              ),
              _trendStat(
                context,
                l.totalDistanceLabel,
                '${displayTrends.map((t) => t.distanceKm).reduce((a, b) => a + b).toStringAsFixed(1)} km',
              ),
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
      mock.add(
        DrivingTrend(
          date: now.subtract(Duration(days: i)),
          safetyScore: 60 + rng.nextInt(35),
          distanceKm: 2.0 + rng.nextDouble() * 8,
          alertCount: rng.nextInt(8),
        ),
      );
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
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: _textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Done Button ───
  Widget _buildDoneButton(BuildContext context) {
    final l = AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PreTripFlowView()),
          );
        },
        icon: const Icon(Icons.check_rounded, size: 18),
        label: Text(
          l.done,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───
  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: _primaryBlue,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _softBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return _primaryBlue;
    if (score >= 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  String _scoreMessage(AppLocalizations l, int score) {
    if (score >= 90) return l.scoreExcellent;
    if (score >= 80) return l.scoreGreat;
    if (score >= 70) return l.scoreGood;
    if (score >= 50) return l.scoreNeedsImprovement;
    return l.scoreDriveCarefully;
  }

  Color _alertSeverityColor(BuildContext context, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => _textMuted,
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
  final Color color;

  _ScoreRingPainter({
    required this.score,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = const Color(0xFFE5EAF2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.25,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 1.25,
      math.pi * 1.5 * score,
      false,
      scorePaint,
    );

    final dotAngle = -math.pi * 1.25 + (math.pi * 1.5 * score);
    final dot = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    canvas.drawCircle(
      dot,
      4.2,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      dot,
      3.1,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) {
    return old.score != score || old.color != color;
  }
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

    final points = <Offset>[];

    for (int i = 0; i < scores.length; i++) {
      final x = padding + i * stepX;
      final y = padding + chartH - (scores[i] / 100 * chartH);
      points.add(Offset(x, y));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EAF2)
      ..strokeWidth = 0.6;

    for (int i = 0; i <= 4; i++) {
      final y = padding + chartH * i / 4;
      canvas.drawLine(
        Offset(padding, y),
        Offset(w - padding, y),
        gridPaint,
      );
    }

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
            const Color(0xFF2563FF).withValues(alpha: 0.16),
            const Color(0xFF2563FF).withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF2563FF)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(linePath, linePaint);
    }

    for (final p in points) {
      canvas.drawCircle(
        p,
        4,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        p,
        3,
        Paint()..color = const Color(0xFF2563FF),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter old) => true;
}