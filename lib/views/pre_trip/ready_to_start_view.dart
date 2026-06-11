import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/l10n/name_localisor.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../controllers/trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';
import '../during_trip/driving_hud_view.dart';

class ReadyToStartView extends StatelessWidget {
  const ReadyToStartView({super.key});

  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _cardBorder = Color(0xFFEDEFF4);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final driver = context.read<AuthController>().authenticatedDriver;
    final vehicle = context.read<VehicleController>().assignedVehicle;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildHero(),
          const SizedBox(height: 22),
          Text(
            l.readyToDrive,
            style: GoogleFonts.poppins(
              color: AppTheme.primary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.allVerificationCompleted,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _textGrey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(context, driver, vehicle),
          const SizedBox(height: 26),

          AppTheme.gradientButton(
            label: l.startVehicle,
            icon: Icons.power_settings_new_rounded,
            onPressed: () => _showStartConfirmation(context),
            height: 58,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<PreTripController>().reset();
              context.read<AuthController>().reset();
            },
            child: Text(
              l.cancelReset,
              style: GoogleFonts.poppins(
                color: AppTheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      width: 168,
      height: 160,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.04),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Image.asset(AppImages.vehicle, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 28,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.successGradient,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, dynamic driver, dynamic vehicle) {
    final l = AppLocalizations.of(context);
    final String vehicleText = vehicle != null
        ? '${vehicle.make} ${vehicle.model} , ${vehicle.registrationNumber}'
        : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildRow(
            AppImages.driver,
            l.driver,
            localizedName(driver?.name ?? l.unknown, l.locale),
          ),
          _divider(),
          _buildRow(
            AppImages.vehicleIcon,
            l.vehicle,
            vehicleText,
          ),
          _divider(),
          _buildRow(
            AppImages.inspectionIcon,
            l.inspection,
            l.passed,
          ),
          _divider(),
          _buildRow(
            AppImages.time,
            l.time,
            _currentDateTime(l),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String iconAsset, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Image.asset(iconAsset, width: 40, height: 40, fit: BoxFit.contain),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(color: _textGrey, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(color: _cardBorder, height: 1, thickness: 1);

  String _currentDateTime(AppLocalizations l) {
    final months = l.monthsShort.split('|');
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? 'pm' : 'am';
    final time =
        '${h.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
    final monthName =
        (now.month - 1) < months.length ? months[now.month - 1] : '${now.month}';
    return '$time . ${now.day} $monthName ${now.year}';
  }

  void _showStartConfirmation(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                child: const Icon(Icons.check_circle_rounded,
                    size: 40, color: AppTheme.accent),
              ),
              const SizedBox(height: 20),
              Text(
                l.vehicleAuthorized,
                style: TextStyle(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                l.driveStarted,
                style: TextStyle(
                    color: AppTheme.of(context).textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppTheme.gradientButton(
                label: l.startDriving,
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