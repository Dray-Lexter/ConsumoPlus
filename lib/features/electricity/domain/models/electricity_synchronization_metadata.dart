enum ElectricitySynchronizationStatus { never, inProgress, success, failed }

class ElectricitySynchronizationMetadata {
  const ElectricitySynchronizationMetadata({
    required this.providerId,
    required this.contractNumber,
    required this.lastAttemptAt,
    required this.lastSuccessfulSyncAt,
    required this.status,
    required this.insertedConsumptionRecords,
    required this.updatedConsumptionRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
    required this.accountStatusUpdated,
    required this.supplyDetailsUpdated,
    this.sanitizedErrorCode,
  });

  final String providerId;
  final String contractNumber;
  final DateTime lastAttemptAt;
  final DateTime? lastSuccessfulSyncAt;
  final ElectricitySynchronizationStatus status;
  final String? sanitizedErrorCode;
  final int insertedConsumptionRecords;
  final int updatedConsumptionRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;
  final bool accountStatusUpdated;
  final bool supplyDetailsUpdated;
}
