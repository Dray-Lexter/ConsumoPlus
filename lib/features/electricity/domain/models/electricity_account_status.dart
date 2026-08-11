class ElectricityAccountStatus {
  const ElectricityAccountStatus({
    required this.providerId,
    required this.contractNumber,
    required this.billingYear,
    required this.billingMonth,
    required this.sourcePeriodCode,
    required this.currentBillingCents,
    required this.previousDebtCents,
    required this.totalDebtCents,
    required this.amountPaidCents,
    required this.totalBalanceCents,
    required this.synchronizedAt,
    this.dueDate,
    this.issueDate,
    this.readingDate,
    this.previousReadingDate,
  });

  final String providerId;
  final String contractNumber;
  final int billingYear;
  final int billingMonth;
  final String sourcePeriodCode;
  final int currentBillingCents;
  final int previousDebtCents;
  final int totalDebtCents;
  final int amountPaidCents;
  final int totalBalanceCents;
  final DateTime? dueDate;
  final DateTime? issueDate;
  final DateTime? readingDate;
  final DateTime? previousReadingDate;
  final DateTime synchronizedAt;

  String get naturalKey => '$providerId|$contractNumber|$sourcePeriodCode';
}
