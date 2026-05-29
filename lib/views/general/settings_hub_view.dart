import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'profile_view.dart';
import 'notification_center_view.dart';
import 'trip_history_view.dart';
import 'privacy_controls_view.dart';
import 'help_support_view.dart';

class SettingsHubView extends StatelessWidget {
  const SettingsHubView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.read<AuthController>();
    final driver = auth.authenticatedDriver;
    final size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.of(context).surface,
        body: Stack(
          children: [
            // Top gradient background
            Container(
              height: size.height * 0.32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context).settings,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4ADE80),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'v1.0.0',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile card (over gradient)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildProfileCard(
                      context,
                      driver?.name ?? 'Driver',
                      driver?.licenseNumber ?? '',
                      driver?.id ?? 'DRV-001',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick stats row
                          _buildQuickStats(context, settings),
                          const SizedBox(height: 18),

                          _sectionLabel(context, AppLocalizations.of(context).general),
                          const SizedBox(height: 10),
                          _buildMenuGroup(context, [
                            _MenuItem(
                              Icons.person_rounded,
                              const Color(0xFF3B82F6),
                              AppLocalizations.of(context).profileManagement,
                              AppLocalizations.of(context).licenseBiometrics,
                              () => _push(context, const ProfileView()),
                            ),
                            _MenuItem(
                              Icons.notifications_rounded,
                              const Color(0xFFF59E0B),
                              AppLocalizations.of(context).notificationCenter,
                              '${settings.unreadCount} ${AppLocalizations.of(context).unread}',
                              () => _push(
                                context,
                                const NotificationCenterView(),
                              ),
                              badge: settings.unreadCount,
                            ),
                            _MenuItem(
                              Icons.history_rounded,
                              const Color(0xFF10B981),
                              AppLocalizations.of(context).tripHistory,
                              '${settings.tripHistory.length} ${AppLocalizations.of(context).tripsRecorded}',
                              () => _push(context, const TripHistoryView()),
                            ),
                          ]),

                          const SizedBox(height: 18),
                          _sectionLabel(context, AppLocalizations.of(context).privacySecurity),
                          const SizedBox(height: 10),
                          _buildMenuGroup(context, [
                            _MenuItem(
                              Icons.shield_rounded,
                              const Color(0xFF8B5CF6),
                              AppLocalizations.of(context).privacyControls,
                              AppLocalizations.of(context).biometricsConsentData,
                              () => _push(context, const PrivacyControlsView()),
                            ),
                          ]),

                          const SizedBox(height: 18),
                          _sectionLabel(context, AppLocalizations.of(context).preferences),
                          const SizedBox(height: 10),
                          _buildPreferencesCard(context, settings),

                          const SizedBox(height: 18),
                          _sectionLabel(context, AppLocalizations.of(context).support),
                          const SizedBox(height: 10),
                          _buildMenuGroup(context, [
                            _MenuItem(
                              Icons.help_outline_rounded,
                              const Color(0xFF6B7280),
                              AppLocalizations.of(context).helpSupport,
                              AppLocalizations.of(context).faqsReportContact,
                              () => _push(context, const HelpSupportView()),
                            ),
                          ]),

                          const SizedBox(height: 24),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.shield_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Proximity Guard Drive',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.of(context).textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Version 1.0.0 · Build 42',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.of(context).textMuted.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile Card ───
  Widget _buildProfileCard(
    BuildContext context,
    String name,
    String license,
    String id,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.of(context).textPrimary;

    return GestureDetector(
      onTap: () => _push(context, const ProfileView()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar with gradient ring
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: GoogleFonts.poppins(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _profileChip(context, 
                        Icons.badge_rounded,
                        license.isEmpty ? '—' : license,
                      ),
                      const SizedBox(width: 6),
                      _profileChip(context, Icons.fingerprint_rounded, id),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileChip(BuildContext context, IconData icon, String text) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.of(context).textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick Stats ───
  Widget _buildQuickStats(BuildContext context, SettingsController settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.of(context).textPrimary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppTheme.of(context).textMuted;
    final trips = settings.tripHistory;
    final totalKm = trips.fold<double>(0, (sum, t) => sum + t.distanceKm);
    final avgScore = trips.isEmpty
        ? 0
        : trips.fold<int>(0, (sum, t) => sum + t.safetyScore) ~/ trips.length;

    return Row(
      children: [
        _statCard(
          icon: Icons.route_rounded,
          color: const Color(0xFF3B82F6),
          value: '${trips.length}',
          label: 'Trips',
          cardColor: cardColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(width: 8),
        _statCard(
          icon: Icons.straighten_rounded,
          color: const Color(0xFF10B981),
          value: '${totalKm.toStringAsFixed(0)} km',
          label: 'Distance',
          cardColor: cardColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(width: 8),
        _statCard(
          icon: Icons.shield_rounded,
          color: const Color(0xFFF59E0B),
          value: '$avgScore',
          label: 'Avg Score',
          cardColor: cardColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
        const SizedBox(width: 8),
        _statCard(
          icon: Icons.notifications_rounded,
          color: const Color(0xFFEF4444),
          value: '${settings.unreadCount}',
          label: 'Unread',
          cardColor: cardColor,
          textPrimary: textPrimary,
          textMuted: textMuted,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color cardColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Menu Group ───
  Widget _buildMenuGroup(BuildContext context, List<_MenuItem> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : AppTheme.of(context).textPrimary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppTheme.of(context).textMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Divider(
                height: 0.5,
                color: dividerColor,
                indent: 60,
                endIndent: 16,
              );
            }
            final item = items[i ~/ 2];
            return _buildMenuItem(context, item, textPrimary, textMuted);
          }),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItem item, Color textPrimary, Color textMuted) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item.color, item.color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.poppins(
                        color: textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.danger,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.badge}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.of(context).textMuted.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Preferences Card ───
  Widget _buildPreferencesCard(
    BuildContext context,
    SettingsController settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : AppTheme.of(context).textPrimary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppTheme.of(context).textMuted;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : AppTheme.of(context).textSecondary;
    final chipBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Theme row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).appearance,
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _themeLabel(context, settings.themeMode),
                        style: GoogleFonts.poppins(
                          color: textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildThemeSwitcher(context, settings),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            color: dividerColor,
            indent: 60,
            endIndent: 16,
          ),
          // Language row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLanguageSheet(context, settings),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).language,
                            style: GoogleFonts.poppins(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            SettingsController.supportedLocales[settings
                                    .locale] ??
                                'English',
                            style: GoogleFonts.poppins(
                              color: textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        settings.locale.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.of(context).textMuted.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitcher(BuildContext context, SettingsController settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final switcherBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final selectedBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final selectedColor = isDark ? Colors.white : AppTheme.of(context).textPrimary;
    final unselectedColor = isDark ? const Color(0xFF64748B) : AppTheme.of(context).textMuted;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: switcherBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _themeOption(
            Icons.wb_sunny_rounded,
            'Light',
            settings.themeMode == ThemeMode.light,
            () => settings.setThemeMode(ThemeMode.light),
            selectedBg: selectedBg,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          const SizedBox(width: 2),
          _themeOption(
            Icons.phone_android_rounded,
            'Auto',
            settings.themeMode == ThemeMode.system,
            () => settings.setThemeMode(ThemeMode.system),
            selectedBg: selectedBg,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
          const SizedBox(width: 2),
          _themeOption(
            Icons.dark_mode_rounded,
            'Dark',
            settings.themeMode == ThemeMode.dark,
            () => settings.setThemeMode(ThemeMode.dark),
            selectedBg: selectedBg,
            selectedColor: selectedColor,
            unselectedColor: unselectedColor,
          ),
        ],
      ),
    );
  }

  Widget _themeOption(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap, {
    required Color selectedBg,
    required Color selectedColor,
    required Color unselectedColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 14,
          color: selected ? selectedColor : unselectedColor,
        ),
      ),
    );
  }

  // ─── Section Label ───
  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: AppTheme.of(context).textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  // ─── Language Sheet ───
  void _showLanguageSheet(BuildContext context, SettingsController settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : AppTheme.of(context).textPrimary;
    final textMuted = isDark ? const Color(0xFF64748B) : AppTheme.of(context).textMuted;
    final chipBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.translate_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).selectLanguage,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: dividerColor),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: SettingsController.supportedLocales.entries.map((
                    e,
                  ) {
                    final selected = settings.locale == e.key;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          settings.setLocale(e.key);
                          Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppTheme.primary.withValues(alpha: 0.1)
                                      : chipBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    e.key.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      color: selected
                                          ? AppTheme.primary
                                          : textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.poppins(
                                    color: selected
                                        ? AppTheme.primary
                                        : textPrimary,
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (selected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ───
  String _themeLabel(BuildContext context, ThemeMode mode) {
    final l = AppLocalizations.of(context);
    return switch (mode) {
      ThemeMode.system => l.autoSystem,
      ThemeMode.light => l.lightMode,
      ThemeMode.dark => l.darkMode,
    };
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  const _MenuItem(
    this.icon,
    this.color,
    this.label,
    this.subtitle,
    this.onTap, {
    this.badge = 0,
  });
}
