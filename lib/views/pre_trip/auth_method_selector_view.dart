import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/auth_result_model.dart';
import '../theme/app_theme.dart';
import 'face_auth_view.dart';
import 'pin_auth_view.dart';
import 'rfid_auth_view.dart';
import 'mobile_approval_view.dart';

class AuthMethodSelectorView extends StatelessWidget {
  const AuthMethodSelectorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // if (authController.currentMethod != null &&
        //     authController.status != AuthStatus.idle) {
        //   return _buildActiveAuthView(authController.currentMethod!);
        // }

        if (authController.currentMethod != null) {
  return _buildActiveAuthView(authController.currentMethod!);
}

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).verifyIdentity,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).chooseAuthMethod,
                style: TextStyle(
                  color: AppTheme.of(context).textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildAuthOption(
                context,
                icon: Icons.face_retouching_natural,
                title: AppLocalizations.of(context).faceRecognition,
                subtitle: AppLocalizations.of(context).instantVerification,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                recommended: true,
                onTap: () => authController.authenticateWithFace(),
              ),
              const SizedBox(height: 14),
              _buildAuthOption(
                context,
                icon: Icons.dialpad_rounded,
                title: AppLocalizations.of(context).securityPin,
                subtitle: AppLocalizations.of(context).enterPinCode,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                onTap: () => authController.selectMethod(AuthMethod.pin),
              ),
              const SizedBox(height: 14),
              _buildAuthOption(
                context,
                icon: Icons.contactless_rounded,
                title: AppLocalizations.of(context).nfcRfidCard,
                subtitle: AppLocalizations.of(context).tapCard,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                onTap: () => authController.authenticateWithRfid(),
              ),
              const SizedBox(height: 14),
              _buildAuthOption(
                context,
                icon: Icons.phone_iphone_rounded,
                title: AppLocalizations.of(context).managerApproval,
                subtitle: AppLocalizations.of(context).requestAuth,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                ),
                onTap: () => authController.requestMobileApproval(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveAuthView(AuthMethod method) {
    switch (method) {
      case AuthMethod.face:
        return const FaceAuthView();
      case AuthMethod.pin:
        return const PinAuthView();
      case AuthMethod.rfid:
        return const RfidAuthView();
      case AuthMethod.mobileApproval:
        return const MobileApprovalView();
    }
  }

  Widget _buildAuthOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
    bool recommended = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: recommended
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.of(context).cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: AppTheme.of(context).textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REC',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.of(context).textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.of(context).cardBorder.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.of(context).textMuted,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

