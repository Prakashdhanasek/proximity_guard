import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/general_models.dart';
import '../theme/app_theme.dart';

class PrivacyControlsView extends StatelessWidget {
  const PrivacyControlsView({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Consumer<SettingsController>(
            builder: (context, settings, _) {
              return Column(
                children: [
                  _header(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _biometricTemplatesCard(context, settings),
                          const SizedBox(height: 14),
                          _consentCard(context, settings),
                          const SizedBox(height: 14),
                          _dataManagementCard(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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
            AppLocalizations.of(context).privacyControls,
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

  Widget _biometricTemplatesCard(
    BuildContext context,
    SettingsController settings,
  ) {
    final l = AppLocalizations.of(context);
    final templates = settings.biometricTemplates;

    return _card(
      context: context,
      title: l.biometricTemplates,
      icon: Icons.fingerprint_rounded,
      children: [
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l.noBiometricData,
              style: GoogleFonts.poppins(
                color: AppTheme.of(context).textMuted,
                fontSize: 13,
              ),
            ),
          ),
        ...templates.map((t) => _templateRow(context, t, settings)),
        const SizedBox(height: 8),
        Text(
          l.biometricEncryptedNote,
          style: GoogleFonts.poppins(
            color: AppTheme.of(context).textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _templateRow(
    BuildContext context,
    BiometricTemplate t,
    SettingsController settings,
  ) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.of(context).surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${l.enrolled} ${_formatDate(context, t.enrolledAt)}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context, t, settings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.deleteWord,
                style: GoogleFonts.poppins(
                  color: AppTheme.danger,
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

  Widget _consentCard(BuildContext context, SettingsController settings) {
    final l = AppLocalizations.of(context);
    return _card(
      context: context,
      title: l.consentManagement,
      icon: Icons.verified_user_rounded,
      children: [
        _toggleRow(
          context: context,
          label: l.dataCollectionConsent,
          subtitle: l.dataCollectionConsentSub,
          value: settings.consentGiven,
          onChanged: (v) => settings.toggleConsent(v),
        ),
        const SizedBox(height: 8),
        _infoTile(
          context: context,
          icon: Icons.info_outline_rounded,
          text: l.privacyRegulationNote,
        ),
      ],
    );
  }

  Widget _dataManagementCard(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _card(
      context: context,
      title: l.dataManagement,
      icon: Icons.storage_rounded,
      children: [
        _actionRow(
          context: context,
          icon: Icons.download_rounded,
          color: AppTheme.primary,
          label: l.exportMyData,
          subtitle: l.exportMyDataSub,
          onTap: () => _showSnack(
            context,
            l.exportRequestedSnack,
          ),
        ),
        const SizedBox(height: 6),
        _actionRow(
          context: context,
          icon: Icons.delete_forever_rounded,
          color: AppTheme.danger,
          label: l.deleteAllData,
          subtitle: l.deleteAllDataSub,
          onTap: () => _showDeleteAllDialog(context),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required BuildContext context,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
    );
  }

  Widget _infoTile({required BuildContext context, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: AppTheme.of(context).textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required BuildContext context,
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

  void _confirmDelete(
    BuildContext context,
    BiometricTemplate t,
    SettingsController settings,
  ) {
    final l = AppLocalizations.of(context);
    final label = switch (t.type) {
      BiometricType.face => l.faceRecognition,
      BiometricType.fingerprint => l.fingerprint,
      BiometricType.voice => l.voicePrint,
    };

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${l.deleteWord} $label?',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.deleteTemplateBody,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.of(context).textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.cancel,
              style: GoogleFonts.poppins(
                color: AppTheme.of(context).textMuted,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              settings.deleteBiometricTemplate(t.id);
              Navigator.of(ctx).pop();
            },
            child: Text(
              l.deleteWord,
              style: GoogleFonts.poppins(
                color: AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${l.deleteAllData}?',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.danger,
          ),
        ),
        content: Text(
          l.deleteAllDataBody,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.of(context).textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l.cancel,
              style: GoogleFonts.poppins(
                color: AppTheme.of(context).textMuted,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showSnack(context, l.dataDeletionSnack);
            },
            child: Text(
              l.deleteEverything,
              style: GoogleFonts.poppins(
                color: AppTheme.danger,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime d) {
    final months = AppLocalizations.of(context).monthsShort.split('|');
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 11)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}