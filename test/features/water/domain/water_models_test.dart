import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const providerId = 'eps-tacna';
  const customerCode = 'CLIENTE-DE-PRUEBA';
  final synchronizedAt = DateTime.utc(2026, 8, 4, 10);

  BillingRecord billing({required int month, required String receipt}) {
    return BillingRecord(
      providerId: providerId,
      customerCode: customerCode,
      billingYear: 2026,
      billingMonth: month,
      sourcePeriodLabel: 'MES $month 2026',
      receiptNumber: receipt,
      consumptionCubicMeters: 12.5,
      averageReading: 11.2,
      monthlyChargeCents: 2450,
      overdueMonths: 1,
      outstandingDebtCents: 800,
      totalAmountCents: 3250,
      synchronizedAt: synchronizedAt,
    );
  }

  test('BillingRecord keeps money as cents and exposes its natural key', () {
    final record = billing(month: 7, receipt: 'RECIBO-001');

    expect(record.monthlyChargeCents, isA<int>());
    expect(record.outstandingDebtCents, isA<int>());
    expect(record.totalAmountCents, isA<int>());
    expect(record.naturalKey, 'eps-tacna|CLIENTE-DE-PRUEBA|RECIBO-001');
  });

  test('PaymentRecord natural key includes date and amount', () {
    final record = PaymentRecord(
      providerId: providerId,
      customerCode: customerCode,
      paymentDate: DateTime.utc(2026, 7, 15),
      paymentCenter: 'CENTRO DE PRUEBA',
      paymentYear: 2026,
      paymentMonth: 7,
      documentType: 'REC',
      receiptNumber: 'PAGO-001',
      amountCents: 3180,
      detail: 'PAGO SANITIZADO',
      synchronizedAt: synchronizedAt,
    );

    expect(record.amountCents, isA<int>());
    expect(
      record.naturalKey,
      'eps-tacna|CLIENTE-DE-PRUEBA|PAGO-001|2026-07-15|3180',
    );
  });

  test(
    'WaterAccount represents portal fields that are not exposed as null',
    () {
      final account = WaterAccount(
        providerId: providerId,
        customerCode: customerCode,
        ownerName: 'PERSONA DE PRUEBA',
        synchronizedAt: synchronizedAt,
      );

      expect(account.serviceAddress, isNull);
      expect(account.serviceStatus, isNull);
      expect(account.tariffName, isNull);
      expect(account.meterNumber, isNull);
      expect(account.connectionType, isNull);
    },
  );

  test('WaterSnapshot is immutable and orders billing chronologically', () {
    final older = billing(month: 5, receipt: 'RECIBO-005');
    final newer = billing(month: 7, receipt: 'RECIBO-007');
    final snapshot = WaterSnapshot(
      account: WaterAccount(
        providerId: providerId,
        customerCode: customerCode,
        ownerName: 'PERSONA DE PRUEBA',
        synchronizedAt: synchronizedAt,
      ),
      billingRecords: [newer, older],
      paymentRecords: const [],
      synchronization: SynchronizationMetadata(
        providerId: providerId,
        customerCode: customerCode,
        lastAttemptAt: synchronizedAt,
        lastSuccessfulSyncAt: synchronizedAt,
        status: SynchronizationStatus.success,
        insertedBillingRecords: 2,
        updatedBillingRecords: 0,
        insertedPaymentRecords: 0,
        updatedPaymentRecords: 0,
      ),
    );

    expect(snapshot.latestBilling, same(newer));
    expect(snapshot.billingChronological, [older, newer]);
    expect(() => snapshot.billingRecords.add(older), throwsUnsupportedError);
  });

  test('typed portal errors expose only sanitized code and safe message', () {
    const secret = 'clave-que-no-debe-aparecer';
    final errors = <WaterException>[
      const InvalidCredentialsException(),
      const SessionExpiredException(),
      const PortalUnavailableException(),
      const UnexpectedPortalStructureException(),
      const NetworkTimeoutException(),
      const IncompleteSynchronizationException(),
    ];

    for (final error in errors) {
      expect(error.sanitizedCode, isNotEmpty);
      expect(error.userMessage, isNotEmpty);
      expect(error.toString(), isNot(contains(secret)));
      expect(error.toString(), isNot(contains('<html')));
    }
  });
}
