import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HelpSupportView extends StatelessWidget {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      _quickActions(context),
                      const SizedBox(height: 18),

                      // FAQs
                      _sectionLabel(context, l.faqTitle),
                      const SizedBox(height: 8),
                      _faqCard(context, [
                        _faqItem(context, l.faq1Q, l.faq1A),
                        _faqItem(context, l.faq2Q, l.faq2A),
                        _faqItem(context, l.faq3Q, l.faq3A),
                        _faqItem(context, l.faq4Q, l.faq4A),
                        _faqItem(context, l.faq5Q, l.faq5A),
                        _faqItem(context, l.faq6Q, l.faq6A),
                      ]),
                      const SizedBox(height: 18),

                      // Contact
                      _sectionLabel(context, l.contactLabel),
                      const SizedBox(height: 8),
                      _contactCard(context),
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
            AppLocalizations.of(context).helpSupport,
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

  Widget _quickActions(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        _actionCard(
          context: context,
          icon: Icons.bug_report_rounded,
          color: AppTheme.danger,
          label: l.reportIssue,
          onTap: () => _showSnack(context, l.reportIssueSnack),
        ),
        const SizedBox(width: 10),
        _actionCard(
          context: context,
          icon: Icons.headset_mic_rounded,
          color: AppTheme.primary,
          label: l.contactManager,
          onTap: () => _showSnack(context, l.contactManagerSnack),
        ),
        const SizedBox(width: 10),
        _actionCard(
          context: context,
          icon: Icons.chat_rounded,
          color: AppTheme.success,
          label: l.liveChat,
          onTap: () => _showSnack(context, l.liveChatSnack),
        ),
      ],
    );
  }

  Widget _actionCard({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.of(context).cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: AppTheme.of(context).textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _faqCard(BuildContext context, List<Widget> items) {
    return Container(
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
      child: Column(children: items),
    );
  }

  Widget _faqItem(BuildContext context, String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: const Icon(
          Icons.help_outline_rounded,
          color: AppTheme.primary,
          size: 18,
        ),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            color: AppTheme.of(context).textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppTheme.of(context).textMuted,
        collapsedIconColor: AppTheme.of(context).textMuted,
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              color: AppTheme.of(context).textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
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
        children: [
          _contactRow(context, Icons.email_rounded, 'support@proximityguard.io'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _contactRow(context, Icons.phone_rounded, '+91 44 2830 XXXX'),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          _contactRow(context, Icons.schedule_rounded, l.supportHours),
        ],
      ),
    );
  }

  Widget _contactRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: AppTheme.of(context).textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 12)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}