import 'billing_record.dart';
import 'payment_record.dart';
import 'synchronization_metadata.dart';
import 'water_account.dart';

class WaterSnapshot {
  WaterSnapshot({
    required this.account,
    required List<BillingRecord> billingRecords,
    required List<PaymentRecord> paymentRecords,
    required this.synchronization,
  }) : billingRecords = List.unmodifiable(billingRecords),
       paymentRecords = List.unmodifiable(paymentRecords);

  final WaterAccount account;
  final List<BillingRecord> billingRecords;
  final List<PaymentRecord> paymentRecords;
  final SynchronizationMetadata synchronization;

  BillingRecord? get latestBilling {
    if (billingRecords.isEmpty) return null;
    return billingRecords.reduce(
      (current, candidate) =>
          _compareBilling(current, candidate) >= 0 ? current : candidate,
    );
  }

  List<BillingRecord> get billingChronological {
    final ordered = [...billingRecords]..sort(_compareBilling);
    return List.unmodifiable(ordered);
  }

  static int _compareBilling(BillingRecord left, BillingRecord right) {
    final yearComparison = left.billingYear.compareTo(right.billingYear);
    if (yearComparison != 0) return yearComparison;
    return left.billingMonth.compareTo(right.billingMonth);
  }
}
