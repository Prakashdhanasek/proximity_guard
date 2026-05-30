import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/trip_alert_model.dart';
import '../theme/app_theme.dart';

class TripAlertOverlay extends StatelessWidget {
  final TripAlertModel alert;
  final VoidCallback onDismiss;

  const TripAlertOverlay({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(context, alert.severity);
    final icon = _alertIcon(alert.type);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alert.title,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.message,
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.close_rounded, size: 14, color: AppTheme.of(context).textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _alertColor(BuildContext context, AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return AppTheme.of(context).textSecondary;
      case AlertSeverity.medium:
        return AppTheme.warning;
      case AlertSeverity.high:
        return const Color(0xFFEA580C);
      case AlertSeverity.critical:
        return AppTheme.danger;
    }
  }

  IconData _alertIcon(AlertType type) {
    switch (type) {
      case AlertType.forwardDistance:
        return Icons.front_hand_rounded;
      case AlertType.drowsiness:
        return Icons.visibility_off_rounded;
      case AlertType.distraction:
        return Icons.phone_android_rounded;
      case AlertType.geofenceBreach:
        return Icons.fence_rounded;
      case AlertType.speedLimit:
        return Icons.speed_rounded;
    }
  }
}
