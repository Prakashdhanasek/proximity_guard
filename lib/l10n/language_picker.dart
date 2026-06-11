import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/controllers/settings_controller.dart';
import 'package:proximity_guard/l10n/app_localizations.dart';
import 'package:proximity_guard/views/theme/app_theme.dart';


/// Opens a bottom sheet to pick the app language. Works anywhere a
/// [SettingsController] is available above in the widget tree (it is, since
/// main.dart provides it). Changing the locale rebuilds the whole app live.
void showLanguagePicker(BuildContext context) {
  final settings = context.read<SettingsController>();
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
                    child: const Icon(Icons.translate_rounded,
                        color: Colors.white, size: 18),
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
                children: SettingsController.supportedLocales.entries.map((e) {
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
                            horizontal: 20, vertical: 12),
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
                                    color:
                                        selected ? AppTheme.primary : textMuted,
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
                                  color:
                                      selected ? AppTheme.primary : textPrimary,
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
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14),
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

/// A small circular globe button. Drop it on any screen (pre-trip flow, splash)
/// so users can switch language BEFORE/DURING verification — handy for someone
/// who can't read the current language. The globe icon is language-neutral.
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key, this.onDark = false});

  /// Set true when placed over a dark/blue background (e.g. splash).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final fg = onDark ? Colors.white : AppTheme.primary;
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppTheme.primary.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showLanguagePicker(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                settings.locale.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}