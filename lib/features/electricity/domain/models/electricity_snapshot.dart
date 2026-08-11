import 'electricity_account.dart';
import 'electricity_account_status.dart';
import 'electricity_consumption_record.dart';
import 'electricity_payment_record.dart';
import 'electricity_synchronization_metadata.dart';

class ElectricitySnapshot {
  ElectricitySnapshot({
    required this.account,
    required List<ElectricityAccountStatus> accountStatuses,
    required List<ElectricityConsumptionRecord> consumptionRecords,
    required List<ElectricityPaymentRecord> paymentRecords,
    required this.synchronization,
  }) : accountStatuses = List.unmodifiable(accountStatuses),
       consumptionRecords = List.unmodifiable(consumptionRecords),
       paymentRecords = List.unmodifiable(paymentRecords);

  final ElectricityAccount account;
  final List<ElectricityAccountStatus> accountStatuses;
  final List<ElectricityConsumptionRecord> consumptionRecords;
  final List<ElectricityPaymentRecord> paymentRecords;
  final ElectricitySynchronizationMetadata synchronization;

  ElectricityAccountStatus? get latestAccountStatus =>
      _latest(accountStatuses, (value) => value.sourcePeriodCode);

  ElectricityConsumptionRecord? get latestConsumption =>
      _latest(consumptionRecords, (value) => value.sourcePeriodCode);

  ElectricityConsumptionRecord? get previousConsumption {
    if (consumptionRecords.length < 2) return null;
    final ordered = [...consumptionRecords]
      ..sort(
        (left, right) =>
            right.sourcePeriodCode.compareTo(left.sourcePeriodCode),
      );
    return ordered[1];
  }

  static T? _latest<T>(List<T> values, String Function(T value) period) {
    if (values.isEmpty) return null;
    return values.reduce(
      (current, candidate) => period(current).compareTo(period(candidate)) >= 0
          ? current
          : candidate,
    );
  }
}
