import 'dart:io';

import 'package:consumo_plus/core/data/local/app_database_schema.dart';
import 'package:consumo_plus/features/electricity/data/local/electricity_database_schema.dart';
import 'package:consumo_plus/features/electricity/data/local/electricity_local_data_source.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  const providerId = 'electrosur';
  const contract = 'CONTRATO-FICTICIO-001';
  final syncAt = DateTime.utc(2026, 8, 11, 14);

  ElectricityAccount account({String meter = 'MEDIDOR-FICTICIO-01'}) =>
      ElectricityAccount(
        providerId: providerId,
        contractNumber: contract,
        ownerName: 'PERSONA FICTICIA',
        serviceAddress: 'AVENIDA FICTICIA 100',
        tariffCode: 'BT5B-FICTICIA',
        connectionType: 'MONOFÁSICA',
        feederType: 'ALIMENTADOR FICTICIO',
        contractedPower: '4.50 kW',
        voltageLevel: '220 V',
        meterNumber: meter,
        synchronizedAt: syncAt,
      );

  ElectricityAccountStatus status({int balance = 11345}) =>
      ElectricityAccountStatus(
        providerId: providerId,
        contractNumber: contract,
        billingYear: 2026,
        billingMonth: 7,
        sourcePeriodCode: '202607',
        currentBillingCents: 12345,
        previousDebtCents: 1000,
        totalDebtCents: 13345,
        amountPaidCents: 2000,
        totalBalanceCents: balance,
        dueDate: DateTime(2026, 8, 25),
        synchronizedAt: syncAt,
      );

  ElectricityConsumptionRecord consumption({int wh = 340000}) =>
      ElectricityConsumptionRecord(
        providerId: providerId,
        contractNumber: contract,
        billingYear: 2026,
        billingMonth: 7,
        sourcePeriodCode: '202607',
        tariffCode: 'BT5B-FICTICIA',
        consumptionWh: wh,
        monthlyChargeCents: 12345,
        synchronizedAt: syncAt,
      );

  ElectricityPaymentRecord payment() => ElectricityPaymentRecord(
    providerId: providerId,
    contractNumber: contract,
    billingYear: 2026,
    billingMonth: 7,
    sourcePeriodCode: '202607',
    paymentDate: DateTime(2026, 7, 20),
    amountCents: 12345,
    paymentCenter: 'CAJA FICTICIA',
    synchronizedAt: syncAt,
  );

  setUpAll(sqfliteFfiInit);

  test('atomic upsert updates changed values without duplicates', () async {
    final database = await _database();
    addTearDown(database.close);
    final local = ElectricityLocalDataSource(database);

    final first = await local.persistSynchronization(
      account: account(),
      accountStatus: status(),
      consumptionRecords: [consumption()],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );
    final second = await local.persistSynchronization(
      account: account(meter: 'MEDIDOR-FICTICIO-02'),
      accountStatus: status(balance: 11000),
      consumptionRecords: [consumption(wh: 341000)],
      paymentRecords: [payment()],
      attemptedAt: syncAt.add(const Duration(hours: 1)),
    );
    final snapshot = await local.loadLatest(providerId);

    expect(first.insertedConsumptionRecords, 1);
    expect(first.insertedPaymentRecords, 1);
    expect(second.updatedConsumptionRecords, 1);
    expect(second.updatedPaymentRecords, 0);
    expect(second.accountStatusUpdated, isTrue);
    expect(second.supplyDetailsUpdated, isTrue);
    expect(snapshot?.consumptionRecords, hasLength(1));
    expect(snapshot?.paymentRecords, hasLength(1));
    expect(snapshot?.consumptionRecords.single.consumptionWh, 341000);
    expect(snapshot?.account.meterNumber, 'MEDIDOR-FICTICIO-02');
  });

  test('failed transaction retains the prior snapshot', () async {
    final database = await _database();
    addTearDown(database.close);
    final local = ElectricityLocalDataSource(database);
    await local.persistSynchronization(
      account: account(),
      accountStatus: status(),
      consumptionRecords: [consumption()],
      paymentRecords: const [],
      attemptedAt: syncAt,
    );

    await expectLater(
      local.persistSynchronization(
        account: ElectricityAccount(
          providerId: providerId,
          contractNumber: contract,
          ownerName: '',
          serviceAddress: 'AVENIDA FICTICIA 100',
          tariffCode: 'BT5B-FICTICIA',
          synchronizedAt: syncAt,
        ),
        accountStatus: status(balance: 1),
        consumptionRecords: const [],
        paymentRecords: const [],
        attemptedAt: syncAt,
      ),
      throwsA(isA<DatabaseException>()),
    );

    expect(
      (await local.loadLatest(providerId))?.account.ownerName,
      'PERSONA FICTICIA',
    );
    expect(
      (await local.loadLatest(
        providerId,
      ))?.latestAccountStatus?.totalBalanceCents,
      11345,
    );
  });

  test('electricity data persists after closing and reopening', () async {
    final directory = await Directory.systemTemp.createTemp(
      'consumo-plus-electricity-db-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}app.db';

    var database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
      ),
    );
    await ElectricityLocalDataSource(database).persistSynchronization(
      account: account(),
      accountStatus: status(),
      consumptionRecords: [consumption()],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );
    await database.close();

    database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
        onUpgrade: AppDatabaseSchema.upgrade,
      ),
    );
    addTearDown(database.close);
    final restored = await ElectricityLocalDataSource(
      database,
    ).loadLatest(providerId);

    expect(restored?.account.contractNumber, contract);
    expect(restored?.latestAccountStatus?.totalBalanceCents, 11345);
    expect(restored?.consumptionRecords, hasLength(1));
    expect(restored?.paymentRecords, hasLength(1));
  });

  test('Electricity deletion preserves Water rows', () async {
    final database = await _database();
    addTearDown(database.close);
    final local = ElectricityLocalDataSource(database);
    await database.insert(WaterDatabaseSchema.accounts, {
      'provider_id': 'eps-tacna',
      'customer_code': 'CLIENTE-FICTICIO',
      'owner_name': 'PERSONA FICTICIA',
      'synchronized_at': syncAt.millisecondsSinceEpoch,
    });
    await local.persistSynchronization(
      account: account(),
      accountStatus: status(),
      consumptionRecords: [consumption()],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );

    await local.deleteProvider(providerId);

    expect(await local.loadLatest(providerId), isNull);
    expect(await database.query(WaterDatabaseSchema.accounts), hasLength(1));
    for (final table in ElectricityDatabaseSchema.tables) {
      expect(await database.query(table), isEmpty, reason: table);
    }
  });
}

Future<Database> _database() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(
    version: AppDatabaseSchema.version,
    onCreate: AppDatabaseSchema.create,
  ),
);
