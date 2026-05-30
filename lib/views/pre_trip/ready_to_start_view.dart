import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../controllers/trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../during_trip/driving_hud_view.dart';

class ReadyToStartView extends StatelessWidget {
  const ReadyToStartView({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = context.read<AuthController>().authenticatedDriver;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Hero visual
          AvatarGlow(
            glowColor: AppTheme.primary,
            glowRadiusFactor: 0.25,
            animate: true,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(Icons.power_settings_new_rounded, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            AppLocalizations.of(context).readyToDrive,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).allVerificationsPassed,
            style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildSummaryCard(context, driver),
          const SizedBox(height: 32),
          // Start button
          AppTheme.gradientButton(
            label: AppLocalizations.of(context).startVehicle,
            icon: Icons.power_settings_new_rounded,
            onPressed: () => _showStartConfirmation(context),
            height: 58,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              context.read<PreTripController>().reset();
              context.read<AuthController>().reset();
            },
            child: Text(AppLocalizations.of(context).cancelReset, style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 13)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic driver) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.of(context).cardBorder),
      ),
      child: Column(
        children: [
          _buildRow(context, Icons.person_rounded, AppLocalizations.of(context).driver, driver?.name ?? 'Unknown'),
          _buildDivider(context),
          _buildRow(context, Icons.verified_rounded, AppLocalizations.of(context).identity, AppLocalizations.of(context).verified),
          _buildDivider(context),
          _buildRow(context, Icons.checklist_rounded, AppLocalizations.of(context).inspection, AppLocalizations.of(context).passed),
          _buildDivider(context),
          _buildRow(context, Icons.schedule_rounded, AppLocalizations.of(context).time, _currentTime()),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.accent),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) => Divider(color: AppTheme.of(context).cardBorder, height: 1);

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
  }

  void _showStartConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.of(context).card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: AppTheme.accent.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.check_circle_rounded, size: 40, color: AppTheme.accent),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).vehicleAuthorized,
                style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).driveStarted,
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppTheme.gradientButton(
                label: AppLocalizations.of(context).startDriving,
                icon: Icons.navigation_rounded,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.read<TripController>().startTrip();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DrivingHudView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
