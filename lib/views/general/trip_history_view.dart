import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/general_models.dart';
import '../theme/app_theme.dart';

class TripHistoryView extends StatelessWidget {
  const TripHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<SettingsController>().tripHistory;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.of(context).surface,
        body: SafeArea(
          child: Column(
            children: [
              _header(context, history.length),
              Expanded(
                child: history.isEmpty
                    ? _emptyState(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tripCard(context, history[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.of(context).cardBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.of(context).textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).tripHistory,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count ${AppLocalizations.of(context).tripsRecorded}',
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

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: AppTheme.of(context).textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noTripsYet,
            style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _tripCard(BuildContext context, TripHistoryEntry trip) {
    final scoreColor = _scoreColor(trip.safetyScore);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.of(context).cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.routeName,
                      style: GoogleFonts.poppins(
                        color: AppTheme.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      trip.formattedDate,
                      style: GoogleFonts.poppins(
                        color: AppTheme.of(context).textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Safety score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, color: scoreColor, size: 12),
                    const SizedBox(width: 3),
                    Text(
                      '${trip.safetyScore}',
                      style: GoogleFonts.poppins(
                        color: scoreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _miniStat(context, Icons.timer_outlined, trip.formattedDuration),
              const SizedBox(width: 16),
              _miniStat(context, Icons.straighten_rounded, trip.formattedDistance),
              const SizedBox(width: 16),
              _miniStat(
                context,
                Icons.speed_rounded,
                '${trip.averageSpeed.toInt()} km/h',
              ),
              const SizedBox(width: 16),
              _miniStat(
                context,
                Icons.warning_amber_rounded,
                '${trip.alertCount} ${AppLocalizations.of(context).alerts}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.of(context).textMuted, size: 13),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: AppTheme.of(context).textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
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
}
