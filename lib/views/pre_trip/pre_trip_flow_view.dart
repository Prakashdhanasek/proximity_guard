// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../controllers/pre_trip_controller.dart';
// import '../../controllers/settings_controller.dart';
// import '../../l10n/app_localizations.dart';
// import '../theme/app_theme.dart';
// import '../general/settings_hub_view.dart';
// import 'auth_method_selector_view.dart';
// import 'vehicle_assignment_view.dart';
// import 'checklist_view.dart';
// import 'ready_to_start_view.dart';

// class PreTripFlowView extends StatelessWidget {
//   const PreTripFlowView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(gradient: AppTheme.of(context).backgroundGradient),
//         child: SafeArea(
//           child: Consumer<PreTripController>(
//             builder: (context, preTripController, _) {
//               return Column(
//                 children: [
//                   _buildHeader(context),
//                   const SizedBox(height: 8),
//                   _buildStepIndicator(context, preTripController.currentStep),
//                   Expanded(
//                     child: AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 350),
//                       switchInCurve: Curves.easeOutCubic,
//                       switchOutCurve: Curves.easeInCubic,
//                       transitionBuilder: (child, animation) {
//                         return FadeTransition(
//                           opacity: animation,
//                           child: SlideTransition(
//                             position: Tween<Offset>(
//                               begin: const Offset(0.04, 0),
//                               end: Offset.zero,
//                             ).animate(animation),
//                             child: child,
//                           ),
//                         );
//                       },
//                       child: _buildCurrentStep(preTripController.currentStep),
//                     ),
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               gradient: AppTheme.primaryGradient,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
//           ),
//           const SizedBox(width: 12),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Proximity Guard',
//                 style: TextStyle(
//                   color: AppTheme.of(context).textPrimary,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.2,
//                 ),
//               ),
//               Text(
//                 AppLocalizations.of(context).preTripVerification,
//                 style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 12),
//               ),
//             ],
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//             decoration: BoxDecoration(
//               color: AppTheme.success.withValues(alpha: 0.1),
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
//             ),
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.circle, color: AppTheme.success, size: 7),
//                 SizedBox(width: 5),
//                 Text(
//                   'ONLINE',
//                   style: TextStyle(
//                     color: AppTheme.success,
//                     fontSize: 9,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 1,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(builder: (_) => const SettingsHubView()),
//               );
//             },
//             child: Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: AppTheme.of(context).cardBorder.withValues(alpha: 0.5),
//                 borderRadius: BorderRadius.circular(11),
//               ),
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Icon(Icons.settings_rounded, color: AppTheme.of(context).textSecondary, size: 19),
//                   if (context.watch<SettingsController>().unreadCount > 0)
//                     Positioned(
//                       top: 5,
//                       right: 5,
//                       child: Container(
//                         width: 8,
//                         height: 8,
//                         decoration: const BoxDecoration(
//                           color: AppTheme.danger,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStepIndicator(BuildContext context, PreTripStep currentStep) {
//     final steps = PreTripStep.values;
//     final currentIndex = steps.indexOf(currentStep);

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         color: AppTheme.of(context).card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppTheme.of(context).cardBorder),
//       ),
//       child: Row(
//         children: List.generate(steps.length * 2 - 1, (index) {
//           if (index.isOdd) {
//             final stepBefore = index ~/ 2;
//             final isCompleted = stepBefore < currentIndex;
//             return Expanded(
//               child: Container(
//                 height: 2,
//                 margin: const EdgeInsets.symmetric(horizontal: 2),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(1),
//                   color: isCompleted ? AppTheme.success : AppTheme.of(context).cardBorder,
//                 ),
//               ),
//             );
//           }

//           final stepIndex = index ~/ 2;
//           final isCompleted = stepIndex < currentIndex;
//           final isCurrent = stepIndex == currentIndex;

//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: isCurrent ? 38 : 32,
//                 height: isCurrent ? 38 : 32,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: isCompleted
//                       ? AppTheme.successGradient
//                       : isCurrent
//                           ? AppTheme.primaryGradient
//                           : null,
//                   color: (!isCompleted && !isCurrent) ? AppTheme.of(context).card : null,
//                   border: (!isCompleted && !isCurrent)
//                       ? Border.all(color: AppTheme.of(context).cardBorder, width: 1.5)
//                       : null,
//                   boxShadow: isCurrent
//                       ? [
//                           BoxShadow(
//                             color: AppTheme.primary.withValues(alpha: 0.35),
//                             blurRadius: 10,
//                           )
//                         ]
//                       : null,
//                 ),
//                 child: Center(
//                   child: isCompleted
//                       ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
//                       : Text(
//                           '${stepIndex + 1}',
//                           style: TextStyle(
//                             color: isCurrent ? Colors.white : AppTheme.of(context).textMuted,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 _stepLabel(context, steps[stepIndex]),
//                 style: TextStyle(
//                   fontSize: 9,
//                   fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
//                   color: isCurrent ? AppTheme.of(context).textPrimary : AppTheme.of(context).textMuted,
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }

//   String _stepLabel(BuildContext context, PreTripStep step) {
//     final l = AppLocalizations.of(context);
//     switch (step) {
//       case PreTripStep.authentication:
//         return l.identity;
//       case PreTripStep.vehicleAssignment:
//         return l.vehicle;
//       case PreTripStep.checklist:
//         return l.inspect;
//       case PreTripStep.ready:
//         return l.start;
//     }
//   }

//   Widget _buildCurrentStep(PreTripStep step) {
//     switch (step) {
//       case PreTripStep.authentication:
//         return const AuthMethodSelectorView(key: ValueKey('auth'));
//       case PreTripStep.vehicleAssignment:
//         return const VehicleAssignmentView(key: ValueKey('vehicle'));
//       case PreTripStep.checklist:
//         return const ChecklistView(key: ValueKey('checklist'));
//       case PreTripStep.ready:
//         return const ReadyToStartView(key: ValueKey('ready'));
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
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
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.of(context).backgroundGradient),
        child: SafeArea(
          child: Consumer<PreTripController>(
            builder: (context, preTripController, _) {
              return Column(
                children: [
                  _buildHeader(context),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Proximity Guard',
                style: TextStyle(
                  color: AppTheme.of(context).textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              Text(
                AppLocalizations.of(context).preTripVerification,
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppTheme.success, size: 7),
                SizedBox(width: 5),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsHubView()),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.of(context).cardBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.settings_rounded, color: AppTheme.of(context).textSecondary, size: 19),
                  if (context.watch<SettingsController>().unreadCount > 0)
                    Positioned(
                      top: 5,
                      right: 5,
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
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    List<PreTripStep> steps,
    PreTripStep currentStep,
  ) {
    final currentIndex = steps.indexOf(currentStep);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.of(context).cardBorder),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isCompleted = stepBefore < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: isCompleted ? AppTheme.success : AppTheme.of(context).cardBorder,
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
                width: isCurrent ? 38 : 32,
                height: isCurrent ? 38 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? AppTheme.successGradient
                      : isCurrent
                          ? AppTheme.primaryGradient
                          : null,
                  color: (!isCompleted && !isCurrent) ? AppTheme.of(context).card : null,
                  border: (!isCompleted && !isCurrent)
                      ? Border.all(color: AppTheme.of(context).cardBorder, width: 1.5)
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
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isCurrent ? Colors.white : AppTheme.of(context).textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _stepLabel(context, steps[stepIndex]),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? AppTheme.of(context).textPrimary : AppTheme.of(context).textMuted,
                  letterSpacing: 0.3,
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