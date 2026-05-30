class DriverModel {
  final String id;
  final String name;
  final String licenseNumber;
  final String profileImagePath;
  final bool isBiometricEnrolled;
  final String rfidTag;
  final String pin;

  DriverModel({
    required this.id,
    required this.name,
    required this.licenseNumber,
    this.profileImagePath = '',
    this.isBiometricEnrolled = false,
    this.rfidTag = '',
    this.pin = '',
  });

  DriverModel copyWith({
    String? id,
    String? name,
    String? licenseNumber,
    String? profileImagePath,
    bool? isBiometricEnrolled,
    String? rfidTag,
    String? pin,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      isBiometricEnrolled: isBiometricEnrolled ?? this.isBiometricEnrolled,
      rfidTag: rfidTag ?? this.rfidTag,
      pin: pin ?? this.pin,
    );
  }
}
