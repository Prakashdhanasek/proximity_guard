import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proximity_guard/l10n/language_picker.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'auth_method_selector_view.dart';
import 'vehicle_assignment_view.dart';
import 'checklist_view.dart';
import 'ready_to_start_view.dart';

/// Pre-trip flow WITHOUT the blue app-bar header. The verification screens
/// (Identity / Vehicle / Inspect / Start) are clean and full; the branded
/// header only appears later, after the ride starts (DrivingHudView).
///
/// A small language (globe) button sits at the top-right so a driver can change
/// the app language BEFORE/DURING verification — important for someone who
/// can't read the current language (the language setting is otherwise only
/// reachable from Settings, after the whole flow).
class PreTripFlowView extends StatelessWidget {
  const PreTripFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).card,
      body: SafeArea(
        child: Consumer<PreTripController>(
          builder: (context, preTripController, _) {
            return Column(
              children: [
                // Top bar: just the language switcher (no branded header).
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: const [
                      Spacer(),
                      LanguageButton(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                    child: _buildCurrentStep(preTripController.currentStep),
                  ),
                ),
              ],
            );
          },
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