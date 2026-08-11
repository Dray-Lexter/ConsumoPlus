import 'dart:io';

import 'package:consumo_plus/features/water/data/local/database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/secure_database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemorySecureValueStore implements SecureValueStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  const providerId = 'eps-tacna';
  const customerCode = 'CLIENTE-DE-PRUEBA';
  final syncAt = DateTime.utc(2026, 8, 4, 12);

  WaterAccount account() => WaterAccount(
    providerId: providerId,
    customerCode: customerCode,
    ownerName: 'PERSONA DE PRUEBA',
    synchronizedAt: syncAt,
  );

  BillingRecord billing({
    required String receipt,
    int debt = 800,
    int total = 3250,
  }) => BillingRecord(
    providerId: providerId,
    customerCode: customerCode,
    billingYear: 2026,
    billingMonth: 7,
    sourcePeriodLabel: 'JULIO 2026',
    receiptNumber: receipt,
    consumptionCubicMeters: 12.5,
    averageReading: 11.2,
    monthlyChargeCents: 2450,
    overdueMonths: 1,
    outstandingDebtCents: debt,
    totalAmountCents: total,
    synchronizedAt: syncAt,
  );

  PaymentRecord payment() => PaymentRecord(
    providerId: providerId,
    customerCode: customerCode,
    paymentDate: DateTime(2026, 7, 15),
    paymentCenter: 'CENTRO DE PRUEBA',
    paymentYear: 2026,
    paymentMonth: 7,
    documentType: 'REC',
    receiptNumber: 'PAGO-001',
    amountCents: 3250,
    detail: 'PAGO SANITIZADO',
    synchronizedAt: syncAt,
  );

  setUpAll(sqfliteFfiInit);

  test('database key is generated once, remembered and deletable', () async {
    final storage = _MemorySecureValueStore();
    var calls = 0;
    final keyStore = SecureDatabaseKeyStore(
      storage: storage,
      randomBytes: (length) {
        calls += 1;
        return List<int>.generate(length, (index) => index);
      },
    );

    final first = await keyStore.getOrCreate();
    final second = await keyStore.getOrCreate();

    expect(first, second);
    expect(first, isNotEmpty);
    expect(calls, 1);
    expect(keyStore.toString(), isNot(contains(first)));

    await keyStore.delete();
    expect(await storage.read(DatabaseKeyStore.waterKeyName), isNull);
  });

  test('concurrent key requests share one secure generation', () async {
    final storage = _MemorySecureValueStore();
    var calls = 0;
    final keyStore = SecureDatabaseKeyStore(
      storage: storage,
      randomBytes: (length) {
        calls += 1;
        return List<int>.filled(length, 7);
      },
    );

    final keys = await Future.wait([
      keyStore.getOrCreate(),
      keyStore.getOrCreate(),
      keyStore.getOrCreate(),
    ]);

    expect(keys.toSet(), hasLength(1));
    expect(calls, 1);
  });

  test('upsert avoids duplicates and updates debt and total', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    final local = WaterLocalDataSource(database);

    final first = await local.persistSynchronization(
      account: account(),
      billingRecords: [billing(receipt: 'RECIBO-001')],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );
    final second = await local.persistSynchronization(
      account: account(),
      billingRecords: [billing(receipt: 'RECIBO-001', debt: 1200, total: 3650)],
      paymentRecords: [payment()],
      attemptedAt: syncAt.add(const Duration(hours: 1)),
    );
    final snapshot = await local.loadLatest(providerId);

    expect(first.insertedBillingRecords, 1);
    expect(first.insertedPaymentRecords, 1);
    expect(second.updatedBillingRecords, 1);
    expect(second.updatedPaymentRecords, 0);
    expect(snapshot, isNotNull);
    expect(snapshot!.billingRecords, hasLength(1));
    expect(snapshot.paymentRecords, hasLength(1));
    expect(snapshot.billingRecords.single.outstandingDebtCents, 1200);
    expect(snapshot.billingRecords.single.totalAmountCents, 3650);
  });

  test('records persist after closing and reopening the database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'consumo-plus-db-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}water.db';

    var database = await _openDatabase(path);
    await WaterLocalDataSource(database).persistSynchronization(
      account: account(),
      billingRecords: [billing(receipt: 'RECIBO-001')],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );
    await database.close();

    database = await _openDatabase(path);
    addTearDown(database.close);
    final snapshot = await WaterLocalDataSource(
      database,
    ).loadLatest(providerId);

    expect(snapshot?.account.ownerName, 'PERSONA DE PRUEBA');
    expect(snapshot?.billingRecords, hasLength(1));
    expect(snapshot?.paymentRecords, hasLength(1));
  });

  test('failed transaction preserves the previous valid snapshot', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    final local = WaterLocalDataSource(database);
    await local.persistSynchronization(
      account: account(),
      billingRecords: [billing(receipt: 'RECIBO-001')],
      paymentRecords: const [],
      attemptedAt: syncAt,
    );

    await expectLater(
      local.persistSynchronization(
        account: account(),
        billingRecords: [
          billing(receipt: 'RECIBO-002'),
          billing(receipt: ''),
        ],
        paymentRecords: const [],
        attemptedAt: syncAt.add(const Duration(hours: 1)),
      ),
      throwsA(isA<DatabaseException>()),
    );

    final snapshot = await local.loadLatest(providerId);
    expect(snapshot!.billingRecords.map((record) => record.receiptNumber), [
      'RECIBO-001',
    ]);
  });

  test('deleteProvider removes only the selected utility data', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    final local = WaterLocalDataSource(database);
    await local.persistSynchronization(
      account: account(),
      billingRecords: [billing(receipt: 'RECIBO-001')],
      paymentRecords: [payment()],
      attemptedAt: syncAt,
    );

    await local.deleteProvider(providerId);

    expect(await local.loadLatest(providerId), isNull);
    for (final table in WaterDatabaseSchema.tables) {
      final rows = await database.query(table);
      expect(rows, isEmpty, reason: table);
    }
  });
}

Future<Database> _openDatabase(String path) {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: WaterDatabaseSchema.version,
      onCreate: WaterDatabaseSchema.create,
    ),
  );
}
