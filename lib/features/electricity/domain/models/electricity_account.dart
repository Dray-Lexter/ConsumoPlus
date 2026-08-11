class ElectricityAccount {
  const ElectricityAccount({
    required this.providerId,
    required this.contractNumber,
    required this.ownerName,
    required this.serviceAddress,
    required this.tariffCode,
    required this.synchronizedAt,
    this.connectionType,
    this.feederType,
    this.contractedPower,
    this.voltageLevel,
    this.meterNumber,
  });

  final String providerId;
  final String contractNumber;
  final String ownerName;
  final String serviceAddress;
  final String tariffCode;
  final String? connectionType;
  final String? feederType;
  final String? contractedPower;
  final String? voltageLevel;
  final String? meterNumber;
  final DateTime synchronizedAt;

  ElectricityAccount copyWith({
    String? contractNumber,
    String? ownerName,
    String? serviceAddress,
    String? tariffCode,
    String? connectionType,
    String? feederType,
    String? contractedPower,
    String? voltageLevel,
    String? meterNumber,
  }) {
    return ElectricityAccount(
      providerId: providerId,
      contractNumber: contractNumber ?? this.contractNumber,
      ownerName: ownerName ?? this.ownerName,
      serviceAddress: serviceAddress ?? this.serviceAddress,
      tariffCode: tariffCode ?? this.tariffCode,
      connectionType: connectionType ?? this.connectionType,
      feederType: feederType ?? this.feederType,
      contractedPower: contractedPower ?? this.contractedPower,
      voltageLevel: voltageLevel ?? this.voltageLevel,
      meterNumber: meterNumber ?? this.meterNumber,
      synchronizedAt: synchronizedAt,
    );
  }
}
