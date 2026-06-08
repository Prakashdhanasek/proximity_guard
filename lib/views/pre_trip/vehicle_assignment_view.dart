import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/vehicle_controller.dart';
import '../../controllers/pre_trip_controller.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';

class VehicleAssignmentView extends StatefulWidget {
  const VehicleAssignmentView({super.key});

  @override
  State<VehicleAssignmentView> createState() => _VehicleAssignmentViewState();
}

class _VehicleAssignmentViewState extends State<VehicleAssignmentView> {
  // Palette (matches the mock)
  static const Color _textDark = Color(0xFF1B2335);
  static const Color _textGrey = Color(0xFF8A93A6);
  static const Color _cardBorder = Color(0xFFEDEFF4);
  static const Color _plateBorder = Color(0xFFDDE2EC);

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
                const CircularProgressIndicator(
                    color: AppTheme.primary, strokeWidth: 2.5),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).loadingVehicle,
                  style: GoogleFonts.poppins(color: _textGrey),
                ),
              ],
            ),
          );
        }

        final vehicle = vehicleController.assignedVehicle;
        if (vehicle == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context).noVehicleAssigned,
              style: GoogleFonts.poppins(color: _textGrey),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).yourVehicle,
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).confirmVehicle,
                style: GoogleFonts.poppins(color: _textGrey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildVehicleCard(vehicle),
              const Spacer(),
              AppTheme.gradientButton(
                label: AppLocalizations.of(context).confirmContinue,
                icon: Icons.arrow_forward_rounded,
                onPressed: () =>
                    context.read<PreTripController>().onVehicleConfirmed(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVehicleCard(dynamic vehicle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──
          Row(
            children: [
              Text(
                'Your Assigned Vehicle',
                style: GoogleFonts.poppins(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Image + details ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AppImages.vehicle,
                width: 112,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicle.make} ${vehicle.model}',
                      style: GoogleFonts.poppins(
                        color: _textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Year: ${vehicle.year}',
                      style: GoogleFonts.poppins(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Number plate
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _plateBorder, width: 1.2),
                      ),
                      child: Text(
                        vehicle.registrationNumber,
                        style: GoogleFonts.poppins(
                          color: _textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Divider(color: _cardBorder, height: 1, thickness: 1),
          const SizedBox(height: 14),

          // ── Fleet / Vehicle ID / Status ──
          Row(
            children: [
              _infoCol(
                Icons.local_shipping_outlined,
                'Fleet',
                vehicle.fleetId,
              ),
              _vDivider(),
              _infoCol(
                Icons.description_outlined,
                'Vehicle ID',
                vehicle.id,
              ),
              _vDivider(),
              _infoCol(
                Icons.speed_outlined,
                'Status',
                'Ready',
                valueColor: AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 38, color: _cardBorder);

  Widget _infoCol(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: _textGrey),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(color: _textGrey, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: valueColor ?? _textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
