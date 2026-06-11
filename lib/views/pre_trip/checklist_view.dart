import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/checklist_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';

class ChecklistView extends StatefulWidget {
  const ChecklistView({super.key});

  @override
  State<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<ChecklistView> {
  final ScrollController _scrollController = ScrollController();
  bool _showCompleted = true;

  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _cardBorder = Color(0xFFEDEFF4);
  static const Color _trackGrey = Color(0xFFE6E9F1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistController>().loadChecklist();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onItemTapped(ChecklistController controller, String id) {
    controller.toggleItem(id);
    final items = controller.items;
    final nextIndex = items.indexWhere((item) => !item.isCompleted);
    if (nextIndex != -1 && _scrollController.hasClients) {
      final targetOffset = (nextIndex * 84.0)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Maps the stable checklist item id ('1'..'6') to a localized title/desc.
  // Keeps the controller unchanged (it still stores English internally).
  String _itemTitle(AppLocalizations l, String id) {
    switch (id) {
      case '1':
        return l.chkExteriorTitle;
      case '2':
        return l.chkLightsTitle;
      case '3':
        return l.chkMirrorsTitle;
      case '4':
        return l.chkFuelTitle;
      case '5':
        return l.chkSeatbeltTitle;
      case '6':
        return l.chkDashTitle;
      default:
        return '';
    }
  }

  String _itemDesc(AppLocalizations l, String id) {
    switch (id) {
      case '1':
        return l.chkExteriorDesc;
      case '2':
        return l.chkLightsDesc;
      case '3':
        return l.chkMirrorsDesc;
      case '4':
        return l.chkFuelDesc;
      case '5':
        return l.chkSeatbeltDesc;
      case '6':
        return l.chkDashDesc;
      default:
        return '';
    }
  }

  String? _iconAssetFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('light') || t.contains('indicator')) return AppImages.light;
    if (t.contains('wiper') || t.contains('mirror')) return AppImages.wiper;
    if (t.contains('fuel') || t.contains('charge')) return AppImages.fuel;
    if (t.contains('seat') || t.contains('belt') || t.contains('cabin')) {
      return AppImages.seatbelt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Consumer<ChecklistController>(
      builder: (context, checklistController, _) {
        final allItems = checklistController.items;
        final displayed = _showCompleted
            ? allItems
            : allItems.where((i) => !i.isCompleted).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.preTripInspection,
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.checkEachItem,
                style: GoogleFonts.poppins(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 18),

              _buildProgressCard(context, checklistController),
              const SizedBox(height: 18),

              Row(
                children: [
                  Text(
                    l.inspectionChecklist,
                    style: GoogleFonts.poppins(
                      color: _textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showCompleted = !_showCompleted),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Text(
                          _showCompleted
                              ? l.collapseCompleted
                              : l.showCompleted,
                          style: GoogleFonts.poppins(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _showCompleted
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = displayed[index];
                    return _buildChecklistItem(
                      item: item,
                      title: _itemTitle(l, item.id),
                      desc: _itemDesc(l, item.id),
                      onTap: () =>
                          _onItemTapped(checklistController, item.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              AppTheme.gradientButton(
                label: l.completeInspection,
                icon: Icons.arrow_forward_rounded,
                onPressed: checklistController.isCompleted
                    ? () =>
                        context.read<PreTripController>().onChecklistCompleted()
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context, ChecklistController controller) {
    final l = AppLocalizations.of(context);
    final pct = (controller.progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.progress,
            style: GoogleFonts.poppins(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${controller.completedCount} / ${controller.totalCount} ${l.checksCompletedWord}',
                style: GoogleFonts.poppins(color: _textGrey, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: 7,
              backgroundColor: _trackGrey,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required dynamic item,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    final bool done = item.isCompleted;
    final String? iconAsset = _iconAssetFor(item.title);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: done ? AppTheme.success.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: done
                  ? AppTheme.success.withValues(alpha: 0.25)
                  : _cardBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              if (iconAsset != null)
                Image.asset(iconAsset, width: 46, height: 46, fit: BoxFit.contain)
              else
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.fact_check_outlined,
                      color: AppTheme.primary, size: 22),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: _textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        desc,
                        style: GoogleFonts.poppins(
                          color: _textGrey,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              done
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.successGradient,
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 17, color: Colors.white),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _trackGrey, width: 1.6),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}