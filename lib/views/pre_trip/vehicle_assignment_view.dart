import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class VehicleAssignmentView extends StatefulWidget {
  const VehicleAssignmentView({super.key});

  @override
  State<VehicleAssignmentView> createState() => _VehicleAssignmentViewState();
}

class _VehicleAssignmentViewState extends State<VehicleAssignmentView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleController>().loadAssignedVehicle('DRV-001');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VehicleController>(
      builder: (context, vehicleController, _) {
        if (vehicleController.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context).loadingVehicle, style: TextStyle(color: AppTheme.of(context).textSecondary)),
              ],
            ),
          );
        }

        final vehicle = vehicleController.assignedVehicle;
        if (vehicle == null) {
          return Center(
            child: Text(AppLocalizations.of(context).noVehicleAssigned, style: TextStyle(color: AppTheme.of(context).textSecondary)),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).yourVehicle,
                style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).confirmVehicle,
                style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildVehicleCard(vehicle),
              const SizedBox(height: 20),
              _buildQuickInfo(vehicle),
              const Spacer(),
              AppTheme.gradientButton(
                label: AppLocalizations.of(context).confirmContinue,
                icon: Icons.check_rounded,
                onPressed: () => context.read<PreTripController>().onVehicleConfirmed(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(dynamic vehicle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: TextStyle(
                        color: AppTheme.of(context).textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Year ${vehicle.year}',
                      style: TextStyle(color: AppTheme.of(context).textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.of(context).surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number_outlined, size: 16, color: AppTheme.of(context).textMuted),
                const SizedBox(width: 8),
                Text(
                  vehicle.registrationNumber,
                  style: TextStyle(
                    color: AppTheme.of(context).textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(dynamic vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.of(context).cardBorder),
      ),
      child: Row(
        children: [
          _buildInfoChip(Icons.group_work_outlined, 'Fleet', vehicle.fleetId),
          Container(width: 1, height: 32, color: AppTheme.of(context).cardBorder),
          _buildInfoChip(Icons.badge_outlined, 'ID', vehicle.id),
          Container(width: 1, height: 32, color: AppTheme.of(context).cardBorder),
          _buildInfoChip(Icons.speed_rounded, 'Status', 'Ready'),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.of(context).textMuted),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: AppTheme.of(context).textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
