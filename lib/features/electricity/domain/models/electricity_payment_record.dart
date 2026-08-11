class ElectricityPaymentRecord {
  const ElectricityPaymentRecord({
    required this.providerId,
    required this.contractNumber,
    required this.billingYear,
    required this.billingMonth,
    required this.sourcePeriodCode,
    required this.paymentDate,
    required this.amountCents,
    required this.paymentCenter,
    required this.synchronizedAt,
  });

  final String providerId;
  final String contractNumber;
  final int billingYear;
  final int billingMonth;
  final String sourcePeriodCode;
  final DateTime paymentDate;
  final int amountCents;
  final String paymentCenter;
  final DateTime synchronizedAt;

  String get naturalKey {
    final month = paymentDate.month.toString().padLeft(2, '0');
    final day = paymentDate.day.toString().padLeft(2, '0');
    return '$providerId|$contractNumber|$sourcePeriodCode|'
        '${paymentDate.year}-$month-$day|$amountCents|$paymentCenter';
  }
}
