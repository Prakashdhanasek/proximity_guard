import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/l10n/name_localisor.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/general_models.dart';
import '../theme/app_theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final driver = context.read<AuthController>().authenticatedDriver;
    final templates = context.watch<SettingsController>().biometricTemplates;

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
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      // Avatar
                      const SizedBox(height: 8),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _initials(driver?.name ?? 'D'),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.of(context).card,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.of(context).cardBorder),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizedName(driver?.name ?? l.driver, l.locale),
                        style: GoogleFonts.poppins(
                          color: AppTheme.of(context).textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'ID: ${driver?.id ?? '—'}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.of(context).textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // License info card
                      _card(
                        context,
                        title: l.licenseInformation,
                        icon: Icons.badge_rounded,
                        children: [
                          _infoRow(context, l.licenseNo, driver?.licenseNumber ?? '—'),
                          _infoRow(context, l.rfidTag, driver?.rfidTag ?? '—'),
                          _infoRow(
                            context,
                            l.statusLabel,
                            l.activeStatus,
                            valueColor: AppTheme.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Biometrics status
                      _card(
                        context,
                        title: l.enrolledBiometrics,
                        icon: Icons.fingerprint_rounded,
                        children: [
                          if (templates.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                l.noBiometricsEnrolled,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.of(context).textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ...templates.map((t) => _biometricRow(context, t)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Vehicle assignment
                      _card(
                        context,
                        title: l.currentVehicle,
                        icon: Icons.directions_car_rounded,
                        children: [
                          _infoRow(context, l.vehicle, 'TN-38-AB-1234'),
                          _infoRow(context, l.typeLabel, l.vehicleTypeVan),
                          _infoRow(context, l.fleet, 'Chennai Metro Fleet'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          Text(
            AppLocalizations.of(context).profile,
            style: GoogleFonts.poppins(
              color: AppTheme.of(context).textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Row(
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
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: valueColor ?? AppTheme.of(context).textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _biometricRow(BuildContext context, BiometricTemplate t) {
    final l = AppLocalizations.of(context);
    final label = switch (t.type) {
      BiometricType.face => l.faceRecognition,
      BiometricType.fingerprint => l.fingerprint,
      BiometricType.voice => l.voicePrint,
    };
    final icon = switch (t.type) {
      BiometricType.face => Icons.face_rounded,
      BiometricType.fingerprint => Icons.fingerprint_rounded,
      BiometricType.voice => Icons.mic_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.success, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  l.enrolled,
                  style: GoogleFonts.poppins(
                    color: AppTheme.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l.activeStatus,
              style: GoogleFonts.poppins(
                color: AppTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}