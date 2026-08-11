class ElectricityConsumptionRecord {
  const ElectricityConsumptionRecord({
    required this.providerId,
    required this.contractNumber,
    required this.billingYear,
    required this.billingMonth,
    required this.sourcePeriodCode,
    required this.tariffCode,
    required this.consumptionWh,
    required this.monthlyChargeCents,
    required this.synchronizedAt,
  });

  final String providerId;
  final String contractNumber;
  final int billingYear;
  final int billingMonth;
  final String sourcePeriodCode;
  final String tariffCode;
  final int consumptionWh;
  final int monthlyChargeCents;
  final DateTime synchronizedAt;

  String get naturalKey => '$providerId|$contractNumber|$sourcePeriodCode';
}
