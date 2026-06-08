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

  // Palette (matches the mock)
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

  /// Maps an item to its asset icon by matching keywords in the title.
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
                AppLocalizations.of(context).preTripInspection,
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check each item before starting your trip',
                style: GoogleFonts.poppins(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 18),

              _buildProgressCard(checklistController),
              const SizedBox(height: 18),

              // Section header + collapse toggle
              Row(
                children: [
                  Text(
                    'Inspection Checklist',
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
                              ? 'Collapse Completed'
                              : 'Show Completed',
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
                      onTap: () =>
                          _onItemTapped(checklistController, item.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              AppTheme.gradientButton(
                label: AppLocalizations.of(context).completeInspection,
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

  Widget _buildProgressCard(ChecklistController controller) {
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
            'Progress',
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
                '${controller.completedCount} of ${controller.totalCount} checks completed',
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
              // Leading icon (asset has its own coloured square; fallback box)
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

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        color: _textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((item.description as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.description,
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

              // Trailing check indicator
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