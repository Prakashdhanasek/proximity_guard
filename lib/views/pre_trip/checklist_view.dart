import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/checklist_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ChecklistView extends StatefulWidget {
  const ChecklistView({super.key});

  @override
  State<ChecklistView> createState() => _ChecklistViewState();
}

class _ChecklistViewState extends State<ChecklistView> {
  final ScrollController _scrollController = ScrollController();

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
    // Find the next unchecked item and scroll to it
    final items = controller.items;
    final nextIndex = items.indexWhere((item) => !item.isCompleted);
    if (nextIndex != -1) {
      final targetOffset = (nextIndex * 78.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChecklistController>(
      builder: (context, checklistController, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).preTripInspection,
                style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).tapEachItem,
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildProgressCard(checklistController),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: checklistController.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = checklistController.items[index];
                    return _buildChecklistItem(item: item, onTap: () => _onItemTapped(checklistController, item.id));
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppTheme.gradientButton(
                label: AppLocalizations.of(context).completeInspection,
                icon: checklistController.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                onPressed: checklistController.isCompleted
                    ? () => context.read<PreTripController>().onChecklistCompleted()
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(ChecklistController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.of(context).cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: controller.progress,
                  strokeWidth: 4,
                  color: AppTheme.success,
                  backgroundColor: AppTheme.of(context).cardBorder,
                ),
                Text(
                  '${(controller.progress * 100).toInt()}%',
                  style: TextStyle(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.completedCount} of ${controller.totalCount} ${AppLocalizations.of(context).itemsChecked}',
                  style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  controller.isCompleted ? AppLocalizations.of(context).allClear : AppLocalizations.of(context).keepGoing,
                  style: TextStyle(
                    color: controller.isCompleted ? AppTheme.success : AppTheme.of(context).textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required dynamic item, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isCompleted ? AppTheme.success.withValues(alpha: 0.05) : AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isCompleted ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.of(context).cardBorder,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: item.isCompleted ? AppTheme.successGradient : null,
                  color: item.isCompleted ? null : Colors.transparent,
                  border: item.isCompleted
                      ? null
                      : Border.all(color: AppTheme.of(context).cardBorder, width: 2),
                ),
                child: item.isCompleted
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.isCompleted ? AppTheme.of(context).textSecondary : AppTheme.of(context).textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.of(context).textMuted,
                      ),
                    ),
                    if (item.description.isNotEmpty && !item.isCompleted) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
