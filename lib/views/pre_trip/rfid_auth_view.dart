import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:proximity_guard/l10n/name_localisor.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class RfidAuthView extends StatelessWidget {
  const RfidAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildNfcVisual(authController.status),
              const SizedBox(height: 36),
              Text(
                authController.status == AuthStatus.success
                    ? l.cardVerified
                    : authController.status == AuthStatus.inProgress
                        ? l.holdCardNearDevice
                        : l.tapYourCard,
                style: TextStyle(
                  color: authController.status == AuthStatus.success
                      ? AppTheme.accent
                      : AppTheme.of(context).textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authController.message,
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (authController.status == AuthStatus.success &&
                  authController.authenticatedDriver != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    localizedName(authController.authenticatedDriver!.name, l.locale),
                    style: const TextStyle(color: AppTheme.accent, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(flex: 1),
              if (authController.status == AuthStatus.success)
                AppTheme.gradientButton(
                  label: l.continueLabel,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.read<PreTripController>().onAuthSuccess(),
                )
              else
                TextButton.icon(
                  onPressed: () => authController.reset(),
                  icon: Icon(Icons.arrow_back_rounded, size: 16, color: AppTheme.of(context).textSecondary),
                  label: Text(l.chooseAnotherMethod,
                      style: TextStyle(color: AppTheme.of(context).textSecondary)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNfcVisual(AuthStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case AuthStatus.inProgress:
        color = const Color(0xFFFF6D00);
        icon = Icons.contactless_rounded;
      case AuthStatus.success:
        color = AppTheme.success;
        icon = Icons.check_circle_rounded;
      case AuthStatus.failed:
        color = AppTheme.danger;
        icon = Icons.error_rounded;
      default:
        color = AppTheme.primary;
        icon = Icons.contactless_rounded;
    }

    return SizedBox(
      width: 200,
      height: 200,
      child: Center(
        child: AvatarGlow(
          glowColor: color,
          glowRadiusFactor: 0.4,
          animate: status == AuthStatus.inProgress,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                if (status == AuthStatus.inProgress)
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color.withValues(alpha: 0.6),
                      backgroundColor: color.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}