import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../models/auth_result_model.dart';
import '../theme/app_theme.dart';

class MobileApprovalView extends StatelessWidget {
  const MobileApprovalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),
              _buildStatusVisual(authController.status),
              const SizedBox(height: 28),
              Text(
                _getTitle(authController.status),
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
              if (authController.status == AuthStatus.awaitingApproval) ...[
                const SizedBox(height: 28),
                _buildApprovalCard(context),
              ],
              if (authController.status == AuthStatus.success &&
                  authController.authenticatedDriver != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    authController.authenticatedDriver!.name,
                    style: const TextStyle(color: AppTheme.accent, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const Spacer(flex: 1),
              if (authController.status == AuthStatus.success)
                AppTheme.gradientButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.read<PreTripController>().onAuthSuccess(),
                )
              else
                TextButton.icon(
                  onPressed: () => authController.reset(),
                  icon: Icon(Icons.close_rounded, size: 16, color: AppTheme.of(context).textSecondary),
                  label: Text('Cancel Request', style: TextStyle(color: AppTheme.of(context).textSecondary)),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusVisual(AuthStatus status) {
    IconData icon;
    Color color;
    bool showProgress;

    switch (status) {
      case AuthStatus.awaitingApproval:
        icon = Icons.schedule_send_rounded;
        color = const Color(0xFFEC407A);
        showProgress = true;
      case AuthStatus.success:
        icon = Icons.verified_rounded;
        color = AppTheme.success;
        showProgress = false;
      case AuthStatus.failed:
        icon = Icons.cancel_rounded;
        color = AppTheme.danger;
        showProgress = false;
      default:
        icon = Icons.phone_iphone_rounded;
        color = AppTheme.primary;
        showProgress = false;
    }

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: Icon(icon, size: 44, color: color),
          ),
          if (showProgress)
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
                backgroundColor: color.withValues(alpha: 0.1),
              ),
            ),
        ],
      ),
    );
  }

  String _getTitle(AuthStatus status) {
    switch (status) {
      case AuthStatus.awaitingApproval:
        return 'Awaiting Approval';
      case AuthStatus.success:
        return 'Access Approved';
      case AuthStatus.failed:
        return 'Request Denied';
      default:
        return 'Manager Approval';
    }
  }

  Widget _buildApprovalCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.of(context).cardBorder),
      ),
      child: Column(
        children: [
          _buildDetailRow(context, Icons.person_outline_rounded, 'Manager', 'Suresh M.'),
          Divider(color: AppTheme.of(context).cardBorder, height: 24),
          _buildDetailRow(context, Icons.directions_car_outlined, 'Vehicle', 'TN 38 AB 1234'),
          Divider(color: AppTheme.of(context).cardBorder, height: 24),
          _buildDetailRow(context, Icons.access_time_rounded, 'Requested', _currentTime()),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.of(context).textMuted),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _currentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
  }
}
