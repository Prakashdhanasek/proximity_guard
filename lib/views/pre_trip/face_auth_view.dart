import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../theme/app_theme.dart';

class FaceAuthView extends StatelessWidget {
  const FaceAuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              _buildScannerFrame(authController.status),
              const SizedBox(height: 36),
              _buildStatusSection(context, authController),
              const Spacer(flex: 1),
              if (authController.status == AuthStatus.success)
                _buildContinueButton(context)
              else if (authController.status == AuthStatus.failed)
                _buildRetrySection(context, authController)
              else
                _buildBackButton(context, authController),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannerFrame(AuthStatus status) {
    Color glowColor;
    IconData icon;

    switch (status) {
      case AuthStatus.inProgress:
        glowColor = AppTheme.primary;
        icon = Icons.face_retouching_natural;
      case AuthStatus.success:
        glowColor = AppTheme.success;
        icon = Icons.check_circle_rounded;
      case AuthStatus.failed:
        glowColor = AppTheme.danger;
        icon = Icons.error_rounded;
      default:
        glowColor = AppTheme.primary;
        icon = Icons.face_retouching_natural;
    }

    return AvatarGlow(
      glowColor: glowColor,
      glowRadiusFactor: 0.3,
      animate: status == AuthStatus.inProgress,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: glowColor.withValues(alpha: 0.08),
          border: Border.all(color: glowColor, width: 3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 60, color: glowColor),
            if (status == AuthStatus.inProgress)
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: glowColor,
                  backgroundColor: glowColor.withValues(alpha: 0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, AuthController controller) {
    String title;
    Color titleColor = AppTheme.of(context).textPrimary;

    switch (controller.status) {
      case AuthStatus.success:
        title = 'Identity Verified';
        titleColor = AppTheme.accent;
      case AuthStatus.inProgress:
        title = 'Scanning...';
      case AuthStatus.failed:
        title = 'Verification Failed';
        titleColor = AppTheme.danger;
      default:
        title = 'Face Authentication';
    }

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          controller.message,
          style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        if (controller.status == AuthStatus.success &&
            controller.authenticatedDriver != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              controller.authenticatedDriver!.name,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return AppTheme.gradientButton(
      label: 'Continue',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => context.read<PreTripController>().onAuthSuccess(),
    );
  }

  Widget _buildRetrySection(BuildContext context, AuthController controller) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => controller.reset(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => controller.authenticateWithFace(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context, AuthController controller) {
    return TextButton.icon(
      onPressed: () => controller.reset(),
      icon: Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.of(context).textSecondary),
      label: Text('Choose another method', style: TextStyle(color: AppTheme.of(context).textSecondary)),
    );
  }
}
