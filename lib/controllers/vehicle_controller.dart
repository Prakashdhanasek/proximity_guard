import 'package:flutter/foundation.dart';
import '../models/vehicle_model.dart';

class VehicleController extends ChangeNotifier {
  VehicleModel? _assignedVehicle;
  bool _isLoading = false;

  // Mock vehicle for demo
  final VehicleModel _mockVehicle = VehicleModel(
    id: 'VH-001',
    registrationNumber: 'TN 38 AB 1234',
    make: 'Tata',
    model: 'Ace Gold',
    year: 2024,
    fleetId: 'FLEET-001',
    assignedDriverId: 'DRV-001',
    status: VehicleStatus.idle,
  );

  VehicleModel? get assignedVehicle => _assignedVehicle;
  bool get isLoading => _isLoading;

  Future<void> loadAssignedVehicle(String driverId) async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    _assignedVehicle = _mockVehicle;
    _isLoading = false;
    notifyListeners();
  }

  void clearVehicle() {
    _assignedVehicle = null;
    notifyListeners();
  }
}
