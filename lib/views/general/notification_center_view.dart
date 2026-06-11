import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/general_models.dart';
import '../theme/app_theme.dart';

class NotificationCenterView extends StatelessWidget {
  const NotificationCenterView({super.key});

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
              final notifications = settings.notifications;
              final unread = settings.unreadCount;

              return Column(
                children: [
                  _header(context, unread, settings),
                  Expanded(
                    child: notifications.isEmpty
                        ? _emptyState(context)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _notificationCard(context, notifications[i], settings),
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

  Widget _header(
    BuildContext context,
    int unread,
    SettingsController settings,
  ) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).notifications,
                  style: GoogleFonts.poppins(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (unread > 0)
                  Text(
                    '$unread ${AppLocalizations.of(context).unread}',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (unread > 0)
            GestureDetector(
              onTap: () => settings.markAllNotificationsRead(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context).readAll,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
            Icons.notifications_off_rounded,
            size: 48,
            color: AppTheme.of(context).textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noNotifications,
            style: GoogleFonts.poppins(color: AppTheme.of(context).textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(BuildContext context, NotificationModel n, SettingsController settings) {
    final color = _typeColor(context, n.type);
    final icon = _typeIcon(n.type);

    return GestureDetector(
      onTap: () {
        if (!n.isRead) settings.markNotificationRead(n.id);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isRead
              ? AppTheme.of(context).card
              : AppTheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead
                ? AppTheme.of(context).cardBorder
                : AppTheme.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _notifTitle(context, n),
                          style: GoogleFonts.poppins(
                            color: AppTheme.of(context).textPrimary,
                            fontSize: 13,
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _timeAgo(context, n.timestamp),
                        style: GoogleFonts.poppins(
                          color: AppTheme.of(context).textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _notifMsg(context, n),
                    style: GoogleFonts.poppins(
                      color: AppTheme.of(context).textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6, top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Localize the mock notifications by id (live ones fall back to stored text)
  String _notifTitle(BuildContext context, NotificationModel n) {
    final l = AppLocalizations.of(context);
    switch (n.id) {
      case '1':
        return l.notif1Title;
      case '2':
        return l.notif2Title;
      case '3':
        return l.notif3Title;
      case '4':
        return l.notif4Title;
      case '5':
        return l.notif5Title;
      case '6':
        return l.notif6Title;
      default:
        return n.title;
    }
  }

  String _notifMsg(BuildContext context, NotificationModel n) {
    final l = AppLocalizations.of(context);
    switch (n.id) {
      case '1':
        return l.notif1Msg;
      case '2':
        return l.notif2Msg;
      case '3':
        return l.notif3Msg;
      case '4':
        return l.notif4Msg;
      case '5':
        return l.notif5Msg;
      case '6':
        return l.notif6Msg;
      default:
        return n.message;
    }
  }

  // Localized relative time computed from the timestamp
  String _timeAgo(BuildContext context, DateTime ts) {
    final l = AppLocalizations.of(context);
    final diff = DateTime.now().difference(ts);
    if (diff.inDays > 0) {
      return l.timeDaysAgo.replaceAll('{n}', '${diff.inDays}');
    }
    if (diff.inHours > 0) {
      return l.timeHoursAgo.replaceAll('{n}', '${diff.inHours}');
    }
    if (diff.inMinutes > 0) {
      return l.timeMinAgo.replaceAll('{n}', '${diff.inMinutes}');
    }
    return l.timeJustNow;
  }

  Color _typeColor(BuildContext context, NotificationType type) {
    return switch (type) {
      NotificationType.tamperAlert => AppTheme.danger,
      NotificationType.unauthorizedAccess => const Color(0xFFEA580C),
      NotificationType.managerMessage => AppTheme.primary,
      NotificationType.systemUpdate => AppTheme.of(context).textSecondary,
      NotificationType.tripReminder => AppTheme.success,
      NotificationType.safetyWarning => AppTheme.warning,
    };
  }

  IconData _typeIcon(NotificationType type) {
    return switch (type) {
      NotificationType.tamperAlert => Icons.gpp_bad_rounded,
      NotificationType.unauthorizedAccess => Icons.no_accounts_rounded,
      NotificationType.managerMessage => Icons.message_rounded,
      NotificationType.systemUpdate => Icons.system_update_rounded,
      NotificationType.tripReminder => Icons.schedule_rounded,
      NotificationType.safetyWarning => Icons.warning_amber_rounded,
    };
  }
}