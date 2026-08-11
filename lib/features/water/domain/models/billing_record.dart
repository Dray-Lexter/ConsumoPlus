class BillingRecord {
  const BillingRecord({
    required this.providerId,
    required this.customerCode,
    required this.billingYear,
    required this.billingMonth,
    required this.sourcePeriodLabel,
    required this.receiptNumber,
    required this.consumptionCubicMeters,
    required this.averageReading,
    required this.monthlyChargeCents,
    required this.overdueMonths,
    required this.outstandingDebtCents,
    required this.totalAmountCents,
    required this.synchronizedAt,
  });

  final String providerId;
  final String customerCode;
  final int billingYear;
  final int billingMonth;
  final String sourcePeriodLabel;
  final String receiptNumber;
  final double consumptionCubicMeters;
  final double averageReading;
  final int monthlyChargeCents;
  final int overdueMonths;
  final int outstandingDebtCents;
  final int totalAmountCents;
  final DateTime synchronizedAt;

  String get naturalKey => '$providerId|$customerCode|$receiptNumber';
}
