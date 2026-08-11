import 'package:consumo_plus/features/home/application/upcoming_dates_controller.dart';
import 'package:consumo_plus/features/home/application/local_upcoming_dates_source.dart';
import 'package:consumo_plus/features/home/application/upcoming_dates_source.dart';
import 'package:consumo_plus/features/home/domain/upcoming_dates_models.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUpcomingDatesSource implements UpcomingDatesSource {
  _FakeUpcomingDatesSource(this.input);

  UpcomingDatesInput input;
  Object? error;
  var loadCount = 0;

  @override
  Future<UpcomingDatesInput> load() async {
    loadCount += 1;
    final failure = error;
    if (failure != null) throw failure;
    return input;
  }
}

void main() {
  test(
    'local source maps account presence and Electrosur dates only',
    () async {
      final source = LocalUpcomingDatesSource(
        loadWater: () async => _waterSnapshot(),
        loadElectricity: () async => _electricitySnapshot(),
      );

      final input = await source.load();

      expect(input.waterConnected, isTrue);
      expect(input.electricityConnected, isTrue);
      expect(input.electricityIssueDate, DateTime(2026, 8, 7));
      expect(input.electricityDueDate, DateTime(2026, 8, 24));
    },
  );

  test('refresh exposes schedules built from local connection state', () async {
    final source = _FakeUpcomingDatesSource(
      const UpcomingDatesInput(
        waterConnected: true,
        electricityConnected: false,
      ),
    );
    final controller = UpcomingDatesController(
      source: source,
      clock: () => DateTime(2026, 8, 11),
    );
    addTearDown(controller.dispose);

    await controller.refresh();

    expect(controller.state.schedules, hasLength(1));
    expect(controller.state.schedules.single.serviceName, 'Agua');
    expect(controller.state.isLoading, isFalse);
    expect(source.loadCount, 1);
  });

  test(
    'every refresh recalculates day distance with the current clock',
    () async {
      var now = DateTime(2026, 8, 11);
      final source = _FakeUpcomingDatesSource(
        const UpcomingDatesInput(
          waterConnected: true,
          electricityConnected: false,
        ),
      );
      final controller = UpcomingDatesController(
        source: source,
        clock: () => now,
      );
      addTearDown(controller.dispose);

      await controller.refresh();
      expect(
        controller.state.schedules.single.indicators.first.distanceText,
        'Faltan 4 días',
      );

      now = DateTime(2026, 8, 15);
      await controller.refresh();

      expect(
        controller.state.schedules.single.indicators.first.distanceText,
        'Esperado hoy',
      );
      expect(source.loadCount, 2);
    },
  );

  test('a local read failure leaves a non-blocking empty state', () async {
    final source = _FakeUpcomingDatesSource(
      const UpcomingDatesInput(
        waterConnected: true,
        electricityConnected: false,
      ),
    );
    final controller = UpcomingDatesController(
      source: source,
      clock: () => DateTime(2026, 8, 11),
    );
    addTearDown(controller.dispose);

    await controller.refresh();
    source.error = StateError('sanitized local failure');

    await controller.refresh();

    expect(controller.state.schedules, isEmpty);
    expect(controller.state.isLoading, isFalse);
  });
}

WaterSnapshot _waterSnapshot() {
  final synchronizedAt = DateTime(2026, 8, 10);
  return WaterSnapshot(
    account: WaterAccount(
      providerId: 'eps-tacna',
      customerCode: 'W-TEST-001',
      ownerName: 'Persona Ficticia',
      synchronizedAt: synchronizedAt,
    ),
    billingRecords: const [],
    paymentRecords: const [],
    synchronization: SynchronizationMetadata(
      providerId: 'eps-tacna',
      customerCode: 'W-TEST-001',
      lastAttemptAt: synchronizedAt,
      lastSuccessfulSyncAt: synchronizedAt,
      status: SynchronizationStatus.success,
      insertedBillingRecords: 0,
      updatedBillingRecords: 0,
      insertedPaymentRecords: 0,
      updatedPaymentRecords: 0,
    ),
  );
}

ElectricitySnapshot _electricitySnapshot() {
  final synchronizedAt = DateTime(2026, 8, 10);
  return ElectricitySnapshot(
    account: ElectricityAccount(
      providerId: 'electrosur',
      contractNumber: 'E-TEST-001',
      ownerName: 'Persona Ficticia',
      serviceAddress: 'Dirección ficticia 123',
      tariffCode: 'TEST',
      synchronizedAt: synchronizedAt,
    ),
    accountStatuses: [
      ElectricityAccountStatus(
        providerId: 'electrosur',
        contractNumber: 'E-TEST-001',
        billingYear: 2026,
        billingMonth: 8,
        sourcePeriodCode: '202608',
        currentBillingCents: 4200,
        previousDebtCents: 0,
        totalDebtCents: 4200,
        amountPaidCents: 0,
        totalBalanceCents: 4200,
        issueDate: DateTime(2026, 8, 7),
        dueDate: DateTime(2026, 8, 24),
        synchronizedAt: synchronizedAt,
      ),
    ],
    consumptionRecords: const [],
    paymentRecords: const [],
    synchronization: ElectricitySynchronizationMetadata(
      providerId: 'electrosur',
      contractNumber: 'E-TEST-001',
      lastAttemptAt: synchronizedAt,
      lastSuccessfulSyncAt: synchronizedAt,
      status: ElectricitySynchronizationStatus.success,
      insertedConsumptionRecords: 0,
      updatedConsumptionRecords: 0,
      insertedPaymentRecords: 0,
      updatedPaymentRecords: 0,
      accountStatusUpdated: false,
      supplyDetailsUpdated: false,
    ),
  );
}
