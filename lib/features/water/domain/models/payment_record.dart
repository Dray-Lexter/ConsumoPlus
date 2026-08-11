class PaymentRecord {
  const PaymentRecord({
    required this.providerId,
    required this.customerCode,
    required this.paymentDate,
    required this.paymentCenter,
    required this.paymentYear,
    required this.paymentMonth,
    required this.documentType,
    required this.receiptNumber,
    required this.amountCents,
    required this.detail,
    required this.synchronizedAt,
  });

  final String providerId;
  final String customerCode;
  final DateTime paymentDate;
  final String paymentCenter;
  final int paymentYear;
  final int paymentMonth;
  final String documentType;
  final String receiptNumber;
  final int amountCents;
  final String detail;
  final DateTime synchronizedAt;

  String get naturalKey {
    final month = paymentDate.month.toString().padLeft(2, '0');
    final day = paymentDate.day.toString().padLeft(2, '0');
    final date = '${paymentDate.year}-$month-$day';
    return '$providerId|$customerCode|$receiptNumber|$date|$amountCents';
  }
}
