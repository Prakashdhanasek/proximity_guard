import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';
import '../general/settings_hub_view.dart';
import 'auth_method_selector_view.dart';
import 'vehicle_assignment_view.dart';
import 'checklist_view.dart';
import 'ready_to_start_view.dart';

class PreTripFlowView extends StatelessWidget {
  const PreTripFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).card,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -22, 0),
              decoration: BoxDecoration(
                color: AppTheme.of(context).card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Consumer<PreTripController>(
                builder: (context, preTripController, _) {
                  return Column(
                    children: [
                      const SizedBox(height: 18),
                      _buildStepIndicator(
                        context,
                        preTripController.activeSteps,
                        preTripController.currentStep,
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildCurrentStep(
                              preTripController.currentStep),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 36),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.appbar),
          fit: BoxFit.cover,
        ),
      ),
      child: Row(
        children: [
          // Back button
          _circleButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Proximity Guard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).preTripVerification,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Online pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppTheme.success, size: 8),
                SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Notification / settings button (uses notification.png)
          _circleButton(
            iconAsset: AppImages.notification,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsHubView()),
              );
            },
            showBadge: context.watch<SettingsController>().unreadCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    IconData? icon,
    String? iconAsset,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (iconAsset != null)
              // The PNG already includes its own circular background.
              ClipOval(
                child: Image.asset(
                  iconAsset,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primary, size: 19),
              ),
            if (showBadge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    List<PreTripStep> steps,
    PreTripStep currentStep,
  ) {
    final currentIndex = steps.indexOf(currentStep);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isCompleted = stepBefore < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20, left: 2, right: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: isCompleted
                      ? AppTheme.success
                      : AppTheme.of(context).cardBorder,
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 36 : 32,
                height: isCurrent ? 36 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? AppTheme.successGradient
                      : isCurrent
                          ? AppTheme.primaryGradient
                          : null,
                  color: (!isCompleted && !isCurrent)
                      ? AppTheme.of(context).card
                      : null,
                  border: (!isCompleted && !isCurrent)
                      ? Border.all(
                          color: AppTheme.of(context).cardBorder, width: 1.5)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : AppTheme.of(context).textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _stepLabel(context, steps[stepIndex]),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent
                      ? AppTheme.of(context).textPrimary
                      : AppTheme.of(context).textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _stepLabel(BuildContext context, PreTripStep step) {
    final l = AppLocalizations.of(context);
    switch (step) {
      case PreTripStep.authentication:
        return l.identity;
      case PreTripStep.vehicleAssignment:
        return l.vehicle;
      case PreTripStep.checklist:
        return l.inspect;
      case PreTripStep.ready:
        return l.start;
    }
  }

  Widget _buildCurrentStep(PreTripStep step) {
    switch (step) {
      case PreTripStep.authentication:
        return const AuthMethodSelectorView(key: ValueKey('auth'));
      case PreTripStep.vehicleAssignment:
        return const VehicleAssignmentView(key: ValueKey('vehicle'));
      case PreTripStep.checklist:
        return const ChecklistView(key: ValueKey('checklist'));
      case PreTripStep.ready:
        return const ReadyToStartView(key: ValueKey('ready'));
    }
  }
}