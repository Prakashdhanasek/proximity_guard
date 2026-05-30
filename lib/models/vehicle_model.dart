class VehicleModel {
  final String id;
  final String registrationNumber;
  final String make;
  final String model;
  final int year;
  final String fleetId;
  final String assignedDriverId;
  final VehicleStatus status;

  VehicleModel({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    this.fleetId = '',
    this.assignedDriverId = '',
    this.status = VehicleStatus.idle,
  });
}

enum VehicleStatus {
  idle,
  inTrip,
  maintenance,
  unauthorized,
}
