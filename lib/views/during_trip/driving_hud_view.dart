import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/trip_controller.dart';
import '../../models/trip_data_model.dart';
import '../../models/trip_alert_model.dart';
import '../theme/app_theme.dart';
import '../general/settings_hub_view.dart';
import '../post_trip/post_trip_summary_view.dart';
import 'trip_alert_overlay.dart';

class DrivingHudView extends StatelessWidget {
  const DrivingHudView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TripController>(
      builder: (context, tripController, _) {
        final data = tripController.tripData;
        final isMinimal = tripController.drivingMode == DrivingMode.minimal;
        final size = MediaQuery.of(context).size;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            body: Stack(
              children: [
                // Full background with painted decorations
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _BackgroundPainter(isOverSpeed: data.isOverSpeed, isDark: isDark),
                  ),
                ),

                // Decorative floating shapes
                ..._buildFloatingShapes(size), 

                SafeArea(
                  child: Column(
                    children: [
                      if (!isMinimal) _buildHeader(context, tripController),
                      if (!isMinimal) const SizedBox(height: 4),
                      if (isMinimal) const Spacer(flex: 2),
                      _buildSpeedSection(context, data),
                      if (!isMinimal) ...[
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: Column(
                              children: [
                                _buildDistanceCard(context, data),
                                const SizedBox(height: 12),
                                _buildRouteCard(context, data),
                                const SizedBox(height: 12),
                                _buildTripStats(context, data),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (isMinimal) const Spacer(flex: 3),
                      _buildBottomBar(context, tripController),
                    ],
                  ),
                ),

                // Alert overlay
                if (tripController.activeAlerts.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + (isMinimal ? 8 : 60),
                    left: 16,
                    right: 16,
                    child: TripAlertOverlay(
                      alert: tripController.activeAlerts.first,
                      onDismiss: () => tripController.dismissAlert(
                        tripController.activeAlerts.first.id,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildFloatingShapes(Size size) {
    return [
      // Top-right circle
      Positioned(
        top: -30,
        right: -40,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      // Top-left small circle
      Positioned(
        top: 80,
        left: -20,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      // Middle-right dotted circle
      Positioned(
        top: size.height * 0.28,
        right: 20,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.08),
              width: 2,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
        ),
      ),
      // Bottom-left decorative ring
      Positioned(
        bottom: 120,
        left: -25,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.06),
              width: 1.5,
            ),
          ),
        ),
      ),
      // Small dots scatter
      Positioned(
        top: 160,
        right: 50,
        child: _dot(6, AppTheme.accentSoft.withValues(alpha: 0.15)),
      ),
      Positioned(
        top: size.height * 0.35,
        left: 40,
        child: _dot(4, AppTheme.primary.withValues(alpha: 0.1)),
      ),
      Positioned(
        bottom: 200,
        right: 60,
        child: _dot(5, AppTheme.success.withValues(alpha: 0.12)),
      ),
      Positioned(
        top: size.height * 0.55,
        right: 30,
        child: _dot(8, AppTheme.primary.withValues(alpha: 0.06)),
      ),
    ];
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHeader(BuildContext context, TripController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driving Mode',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                'Proximity Guard Active',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // LIVE badge with glow
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4ADE80),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedSection(BuildContext context, TripDataModel data) {
    final isOverSpeed = data.isOverSpeed;
    final speedRatio = (data.currentSpeed / (data.speedLimit * 1.5)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isOverSpeed ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle decorative corner shapes inside the card
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isOverSpeed ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            bottom: -10,
            left: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isOverSpeed ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.03),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 170,
                width: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(170, 170),
                      painter: _CircularGaugePainter(
                        progress: speedRatio,
                        isOverSpeed: isOverSpeed,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${data.currentSpeed.toInt()}',
                          style: GoogleFonts.poppins(
                            color: isOverSpeed ? AppTheme.danger : AppTheme.of(context).textPrimary,
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isOverSpeed ? AppTheme.danger : AppTheme.primary)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'km/h',
                            style: GoogleFonts.poppins(
                              color: isOverSpeed ? AppTheme.danger : AppTheme.of(context).textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Speed limit row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _miniInfoChip(
                    context: context,
                    icon: Icons.speed_rounded,
                    label: 'Limit',
                    value: '${data.speedLimit.toInt()}',
                    color: isOverSpeed ? AppTheme.danger : AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 28, color: AppTheme.of(context).cardBorder),
                  const SizedBox(width: 12),
                  _miniInfoChip(
                    context: context,
                    icon: isOverSpeed ? Icons.trending_up_rounded : Icons.check_circle_outline_rounded,
                    label: 'Status',
                    value: isOverSpeed ? 'Over' : 'OK',
                    color: isOverSpeed ? AppTheme.danger : AppTheme.success,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfoChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.of(context).textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceCard(BuildContext context, TripDataModel data) {
    final isTooClose = data.isTooClose;
    final color = isTooClose ? AppTheme.danger : AppTheme.success;
    final distRatio = (data.followingDistance / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isTooClose ? AppTheme.danger.withValues(alpha: 0.2) : AppTheme.of(context).cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: icon + info
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isTooClose ? Icons.warning_rounded : Icons.verified_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTooClose ? 'Too Close!' : 'Safe Distance',
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                // Mini bar
                Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: distRatio,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Right: distance value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.followingDistance.toInt()}m',
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Text(
                'ahead',
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BuildContext context, TripDataModel data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.of(context).cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.routeName,
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(data.routeProgress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented progress bar
          Row(
            children: List.generate(10, (i) {
              final filled = i / 10 < data.routeProgress;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: i < 9 ? 3 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: filled ? AppTheme.primary : AppTheme.of(context).cardBorder,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStats(BuildContext context, TripDataModel data) {
    final duration = data.tripDuration;
    final timeStr = '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context: context,
            icon: Icons.access_time_rounded,
            value: timeStr,
            label: 'Duration',
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            context: context,
            icon: Icons.near_me_rounded,
            value: '${data.distanceCovered.toStringAsFixed(1)} km',
            label: 'Distance',
            color: const Color(0xFF0891B2),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.of(context).cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, TripController controller) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              context: context,
              icon: controller.drivingMode == DrivingMode.minimal
                  ? Icons.fullscreen_rounded
                  : Icons.grid_view_rounded,
              label: controller.drivingMode == DrivingMode.minimal ? 'Full' : 'Minimal',
              onTap: () => controller.toggleDrivingMode(),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              icon: Icons.notifications_none_rounded,
              label: 'Alerts',
              badge: controller.activeAlerts.isNotEmpty ? controller.activeAlerts.length : null,
              onTap: () => _showAlertsSheet(context, controller),
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsHubView()),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showEndTripDialog(context, controller),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.danger.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stop_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'End Trip',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: AppTheme.of(context).textSecondary, size: 23),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 9, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlertsSheet(BuildContext context, TripController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final allAlerts = controller.alerts;
        final activeAlerts = controller.activeAlerts;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.of(context).cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_rounded, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Alerts',
                            style: GoogleFonts.poppins(
                              color: AppTheme.of(context).textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${activeAlerts.length} active · ${allAlerts.length} total',
                            style: GoogleFonts.poppins(
                              color: AppTheme.of(context).textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeAlerts.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          for (final a in activeAlerts) {
                            controller.dismissAlert(a.id);
                          }
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.of(context).textMuted.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.poppins(
                              color: AppTheme.of(context).textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.of(context).cardBorder),
              if (allAlerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 48, color: AppTheme.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No alerts yet',
                        style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Drive safe!',
                        style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: allAlerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final alert = allAlerts[allAlerts.length - 1 - i]; // newest first
                      final color = _sheetAlertColor(alert.severity);
                      final icon = _sheetAlertIcon(alert.type);
                      final isDismissed = alert.isDismissed;

                      return Opacity(
                        opacity: isDismissed ? 0.5 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDismissed ? AppTheme.of(context).surface : AppTheme.of(context).card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDismissed ? AppTheme.of(context).cardBorder : color.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style: GoogleFonts.poppins(
                                        color: isDismissed ? AppTheme.of(context).textMuted : AppTheme.of(context).textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      alert.message,
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.of(context).textMuted,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isDismissed)
                                GestureDetector(
                                  onTap: () => controller.dismissAlert(alert.id),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppTheme.of(context).cardBorder.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.close_rounded, size: 13, color: AppTheme.of(context).textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _sheetAlertColor(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.low => AppTheme.primary,
      AlertSeverity.medium => AppTheme.warning,
      AlertSeverity.high => AppTheme.danger,
      AlertSeverity.critical => const Color(0xFF991B1B),
    };
  }

  IconData _sheetAlertIcon(AlertType type) {
    return switch (type) {
      AlertType.forwardDistance => Icons.swap_horiz_rounded,
      AlertType.drowsiness => Icons.bedtime_rounded,
      AlertType.distraction => Icons.phone_android_rounded,
      AlertType.geofenceBreach => Icons.location_off_rounded,
      AlertType.speedLimit => Icons.speed_rounded,
    };
  }

  void _showEndTripDialog(BuildContext context, TripController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.danger.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.stop_circle_rounded, size: 36, color: AppTheme.danger),
              ),
              const SizedBox(height: 20),
              Text('End Trip?', style: GoogleFonts.poppins(color: AppTheme.of(context).textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'This will stop all monitoring and end the current driving session.',
                style: GoogleFonts.poppins(color: AppTheme.of(context).textSecondary, fontSize: 11, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.of(context).textSecondary,
                        side: BorderSide(color: AppTheme.of(context).cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        controller.endTrip();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const PostTripSummaryView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('End Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom background painter with wave curves, road illustration, and decorations
class _BackgroundPainter extends CustomPainter {
  final bool isOverSpeed;
  final bool isDark;

  _BackgroundPainter({required this.isOverSpeed, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mainColor = isOverSpeed ? const Color(0xFFDC2626) : const Color(0xFF2563EB);

    // Base background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F8FB),
    );

    // Top curved gradient header
    final headerPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.32)
      ..quadraticBezierTo(w * 0.75, h * 0.37, w * 0.5, h * 0.35)
      ..quadraticBezierTo(w * 0.25, h * 0.33, 0, h * 0.38)
      ..close();

    final headerGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isOverSpeed
          ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
          : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
    );

    canvas.drawPath(
      headerPath,
      Paint()..shader = headerGradient.createShader(Rect.fromLTWH(0, 0, w, h * 0.4)),
    );

    // Second wave layer (lighter)
    final wave2 = Path()
      ..moveTo(0, h * 0.30)
      ..quadraticBezierTo(w * 0.3, h * 0.34, w * 0.6, h * 0.31)
      ..quadraticBezierTo(w * 0.85, h * 0.29, w, h * 0.33)
      ..lineTo(w, h * 0.36)
      ..quadraticBezierTo(w * 0.7, h * 0.40, w * 0.4, h * 0.37)
      ..quadraticBezierTo(w * 0.15, h * 0.35, 0, h * 0.40)
      ..close();

    canvas.drawPath(
      wave2,
      Paint()..color = mainColor.withValues(alpha: 0.12),
    );

    // Dotted road-like lines in the header
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Left road line
    for (double y = 0; y < h * 0.32; y += 18) {
      canvas.drawLine(
        Offset(w * 0.15, y),
        Offset(w * 0.15, y + 8),
        roadPaint,
      );
    }

    // Right road line
    for (double y = 0; y < h * 0.32; y += 18) {
      canvas.drawLine(
        Offset(w * 0.85, y),
        Offset(w * 0.85, y + 8),
        roadPaint,
      );
    }

    // Center dashed line (road median)
    final medianPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (double y = 20; y < h * 0.30; y += 24) {
      canvas.drawLine(
        Offset(w * 0.5, y),
        Offset(w * 0.5, y + 12),
        medianPaint,
      );
    }

    // Bottom subtle wave pattern
    final bottomWave = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.92)
      ..quadraticBezierTo(w * 0.25, h * 0.90, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.75, h * 0.94, w, h * 0.91)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      bottomWave,
      Paint()..color = mainColor.withValues(alpha: 0.03),
    );

    // Grid dots pattern in bottom area
    final dotPaint = Paint()..color = mainColor.withValues(alpha: 0.04);
    for (double x = 30; x < w; x += 30) {
      for (double y = h * 0.65; y < h * 0.90; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.isOverSpeed != isOverSpeed || old.isDark != isDark;
}

/// Circular gauge painter
class _CircularGaugePainter extends CustomPainter {
  final double progress;
  final bool isOverSpeed;

  _CircularGaugePainter({required this.progress, required this.isOverSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    // Background track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final isMajor = i % 5 == 0;
      final innerR = radius + 8;
      final outerR = radius + (isMajor ? 16 : 12);
      canvas.drawLine(
        Offset(center.dx + innerR * math.cos(angle), center.dy + innerR * math.sin(angle)),
        Offset(center.dx + outerR * math.cos(angle), center.dy + outerR * math.sin(angle)),
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..strokeWidth = isMajor ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    if (progress <= 0) return;

    final activeColors = isOverSpeed
        ? [const Color(0xFFDC2626), const Color(0xFFF87171)]
        : [const Color(0xFF2563EB), const Color(0xFF60A5FA)];

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: activeColors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // End dot
    final endAngle = startAngle + sweepAngle * progress;
    final dot = Offset(center.dx + radius * math.cos(endAngle), center.dy + radius * math.sin(endAngle));
    canvas.drawCircle(dot, 7, Paint()..color = Colors.white);
    canvas.drawCircle(dot, 5, Paint()..color = isOverSpeed ? const Color(0xFFDC2626) : const Color(0xFF2563EB));
  }

  @override
  bool shouldRepaint(_CircularGaugePainter old) =>
      old.progress != progress || old.isOverSpeed != isOverSpeed;
}
