enum SynchronizationStatus { never, inProgress, success, failed }

class SynchronizationMetadata {
  const SynchronizationMetadata({
    required this.providerId,
    required this.customerCode,
    required this.lastAttemptAt,
    required this.lastSuccessfulSyncAt,
    required this.status,
    required this.insertedBillingRecords,
    required this.updatedBillingRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
    this.sanitizedErrorCode,
  });

  final String providerId;
  final String customerCode;
  final DateTime lastAttemptAt;
  final DateTime? lastSuccessfulSyncAt;
  final SynchronizationStatus status;
  final String? sanitizedErrorCode;
  final int insertedBillingRecords;
  final int updatedBillingRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;
}
