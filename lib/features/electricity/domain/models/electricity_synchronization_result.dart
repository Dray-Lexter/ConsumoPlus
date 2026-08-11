import 'electricity_snapshot.dart';

class ElectricitySynchronizationResult {
  const ElectricitySynchronizationResult({
    required this.snapshot,
    required this.insertedConsumptionRecords,
    required this.updatedConsumptionRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
    required this.accountStatusUpdated,
    required this.supplyDetailsUpdated,
  });

  final ElectricitySnapshot snapshot;
  final int insertedConsumptionRecords;
  final int updatedConsumptionRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;
  final bool accountStatusUpdated;
  final bool supplyDetailsUpdated;
}
