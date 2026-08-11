import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const providerId = 'electrosur';
  const contract = 'CONTRATO-FICTICIO-001';
  final synchronizedAt = DateTime.utc(2026, 8, 11, 14);

  ElectricityConsumptionRecord consumption(int month, int wh) {
    return ElectricityConsumptionRecord(
      providerId: providerId,
      contractNumber: contract,
      billingYear: 2026,
      billingMonth: month,
      sourcePeriodCode: '2026${month.toString().padLeft(2, '0')}',
      tariffCode: 'BT5B-FICTICIA',
      consumptionWh: wh,
      monthlyChargeCents: 7640,
      synchronizedAt: synchronizedAt,
    );
  }

  test('account supports optional secondary supply fields', () {
    final account = ElectricityAccount(
      providerId: providerId,
      contractNumber: contract,
      ownerName: 'PERSONA FICTICIA',
      serviceAddress: 'AVENIDA FICTICIA 100',
      tariffCode: 'BT5B-FICTICIA',
      synchronizedAt: synchronizedAt,
    );

    expect(account.connectionType, isNull);
    expect(account.feederType, isNull);
    expect(account.contractedPower, isNull);
    expect(account.voltageLevel, isNull);
    expect(account.meterNumber, isNull);
  });

  test('period models expose stable provider and contract natural keys', () {
    final status = ElectricityAccountStatus(
      providerId: providerId,
      contractNumber: contract,
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      currentBillingCents: 7640,
      previousDebtCents: 1200,
      totalDebtCents: 8840,
      amountPaidCents: 0,
      totalBalanceCents: 8840,
      synchronizedAt: synchronizedAt,
    );
    final usage = consumption(7, 340000);
    final payment = ElectricityPaymentRecord(
      providerId: providerId,
      contractNumber: contract,
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      paymentDate: DateTime(2026, 7, 20),
      amountCents: 7640,
      paymentCenter: 'CAJA FICTICIA',
      synchronizedAt: synchronizedAt,
    );

    expect(status.naturalKey, '$providerId|$contract|202607');
    expect(usage.naturalKey, '$providerId|$contract|202607');
    expect(
      payment.naturalKey,
      '$providerId|$contract|202607|2026-07-20|7640|CAJA FICTICIA',
    );
  });

  test(
    'snapshot is immutable and computes latest and previous consumption',
    () {
      final older = consumption(6, 280000);
      final latest = consumption(7, 340000);
      final snapshot = ElectricitySnapshot(
        account: ElectricityAccount(
          providerId: providerId,
          contractNumber: contract,
          ownerName: 'PERSONA FICTICIA',
          serviceAddress: 'AVENIDA FICTICIA 100',
          tariffCode: 'BT5B-FICTICIA',
          synchronizedAt: synchronizedAt,
        ),
        accountStatuses: [
          ElectricityAccountStatus(
            providerId: providerId,
            contractNumber: contract,
            billingYear: 2026,
            billingMonth: 7,
            sourcePeriodCode: '202607',
            currentBillingCents: 7640,
            previousDebtCents: 1200,
            totalDebtCents: 8840,
            amountPaidCents: 0,
            totalBalanceCents: 8840,
            synchronizedAt: synchronizedAt,
          ),
        ],
        consumptionRecords: [latest, older],
        paymentRecords: const [],
        synchronization: ElectricitySynchronizationMetadata(
          providerId: providerId,
          contractNumber: contract,
          lastAttemptAt: synchronizedAt,
          lastSuccessfulSyncAt: synchronizedAt,
          status: ElectricitySynchronizationStatus.success,
          insertedConsumptionRecords: 2,
          updatedConsumptionRecords: 0,
          insertedPaymentRecords: 0,
          updatedPaymentRecords: 0,
          accountStatusUpdated: true,
          supplyDetailsUpdated: true,
        ),
      );

      expect(snapshot.latestConsumption, same(latest));
      expect(snapshot.previousConsumption, same(older));
      expect(snapshot.latestAccountStatus?.sourcePeriodCode, '202607');
      expect(
        () => snapshot.consumptionRecords.add(older),
        throwsUnsupportedError,
      );
    },
  );

  test('typed errors expose only sanitized codes and safe messages', () {
    final errors = <ElectricityException>[
      const ElectricityInvalidCredentialsException(),
      const ElectricitySessionExpiredException(),
      const ElectrosurUnavailableException(),
      const ElectricitySectionStructureException('consumptions'),
      const ElectricityLocalStorageException(),
    ];

    for (final error in errors) {
      expect(error.sanitizedCode, isNotEmpty);
      expect(error.userMessage, isNotEmpty);
      expect(error.toString(), isNot(contains('<html')));
      expect(error.toString(), isNot(contains('GstrClave')));
    }
  });

  test('section errors identify the failing safe synchronization boundary', () {
    expect(
      const ElectricitySectionStructureException('response').userMessage,
      contains('respuesta del portal'),
    );
    expect(
      const ElectricitySectionStructureException('account_status').userMessage,
      contains('Estado de cuenta'),
    );
    expect(
      const ElectricitySectionStructureException('consumptions').userMessage,
      contains('Consumos'),
    );
    expect(
      const ElectricitySectionStructureException('payments').userMessage,
      contains('Pagos'),
    );
  });
}
