import 'water_snapshot.dart';

class SynchronizationResult {
  const SynchronizationResult({
    required this.snapshot,
    required this.insertedBillingRecords,
    required this.updatedBillingRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
  });

  final WaterSnapshot snapshot;
  final int insertedBillingRecords;
  final int updatedBillingRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;
}
