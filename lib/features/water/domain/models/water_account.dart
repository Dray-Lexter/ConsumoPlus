class WaterAccount {
  const WaterAccount({
    required this.providerId,
    required this.customerCode,
    required this.ownerName,
    required this.synchronizedAt,
    this.serviceAddress,
    this.serviceStatus,
    this.tariffName,
    this.meterNumber,
    this.connectionType,
  });

  final String providerId;
  final String customerCode;
  final String ownerName;
  final String? serviceAddress;
  final String? serviceStatus;
  final String? tariffName;
  final String? meterNumber;
  final String? connectionType;
  final DateTime synchronizedAt;
}
