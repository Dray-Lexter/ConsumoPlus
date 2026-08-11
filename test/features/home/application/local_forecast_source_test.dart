import 'package:consumo_plus/core/models/utility_type.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:consumo_plus/features/home/application/local_forecast_source.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps only records belonging to each active supply', () async {
    final source = LocalForecastSource(
      loadWater: () async => _waterSnapshot(),
      loadElectricity: () async => _electricitySnapshot(),
    );

    final inputs = await source.load();

    expect(inputs, hasLength(2));
    final water = inputs.first;
    final electricity = inputs.last;
    expect(water.utilityType, UtilityType.water);
    expect(water.observations, hasLength(1));
    expect(water.observations.single.consumption, 12.5);
    expect(water.observations.single.monthlyCostCents, 3450);
    expect(electricity.utilityType, UtilityType.electricity);
    expect(electricity.observations, hasLength(1));
    expect(electricity.observations.single.consumption, 340.5);
    expect(electricity.observations.single.monthlyCostCents, 7890);
  });

  test('returns no forecast inputs when no service is connected', () async {
    final source = LocalForecastSource(
      loadWater: () async => null,
      loadElectricity: () async => null,
    );

    expect(await source.load(), isEmpty);
  });
}

WaterSnapshot _waterSnapshot() {
  final at = DateTime.utc(2026, 8, 11);
  return WaterSnapshot(
    account: WaterAccount(
      providerId: 'eps-tacna',
      customerCode: 'W-ACTIVE',
      ownerName: 'PERSONA FICTICIA',
      synchronizedAt: at,
    ),
    billingRecords: [
      _waterRecord('W-ACTIVE', 'ACTIVE', at),
      _waterRecord('W-OTHER', 'OTHER', at),
    ],
    paymentRecords: const [],
    synchronization: SynchronizationMetadata(
      providerId: 'eps-tacna',
      customerCode: 'W-ACTIVE',
      lastAttemptAt: at,
      lastSuccessfulSyncAt: at,
      status: SynchronizationStatus.success,
      insertedBillingRecords: 0,
      updatedBillingRecords: 0,
      insertedPaymentRecords: 0,
      updatedPaymentRecords: 0,
    ),
  );
}

BillingRecord _waterRecord(String customer, String receipt, DateTime at) =>
    BillingRecord(
      providerId: 'eps-tacna',
      customerCode: customer,
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodLabel: 'JULIO 2026',
      receiptNumber: receipt,
      consumptionCubicMeters: 12.5,
      averageReading: 12,
      monthlyChargeCents: 3450,
      overdueMonths: 0,
      outstandingDebtCents: 99000,
      totalAmountCents: 102450,
      synchronizedAt: at,
    );

ElectricitySnapshot _electricitySnapshot() {
  final at = DateTime.utc(2026, 8, 11);
  return ElectricitySnapshot(
    account: ElectricityAccount(
      providerId: 'electrosur',
      contractNumber: 'E-ACTIVE',
      ownerName: 'PERSONA FICTICIA',
      serviceAddress: 'DIRECCIÓN FICTICIA',
      tariffCode: 'TEST',
      synchronizedAt: at,
    ),
    accountStatuses: const [],
    consumptionRecords: [
      _electricityRecord('E-ACTIVE', at),
      _electricityRecord('E-OTHER', at),
    ],
    paymentRecords: const [],
    synchronization: ElectricitySynchronizationMetadata(
      providerId: 'electrosur',
      contractNumber: 'E-ACTIVE',
      lastAttemptAt: at,
      lastSuccessfulSyncAt: at,
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

ElectricityConsumptionRecord _electricityRecord(String contract, DateTime at) =>
    ElectricityConsumptionRecord(
      providerId: 'electrosur',
      contractNumber: contract,
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      tariffCode: 'TEST',
      consumptionWh: 340500,
      monthlyChargeCents: 7890,
      synchronizedAt: at,
    );
