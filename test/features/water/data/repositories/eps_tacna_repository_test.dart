import 'package:consumo_plus/features/water/data/local/database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/encrypted_water_database.dart';
import 'package:consumo_plus/features/water/data/local/remembered_username_store.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_remote_data_source.dart';
import 'package:consumo_plus/features/water/data/repositories/eps_tacna_repository.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements EpsTacnaRemoteSource {
  _FakeRemote(this.result);

  Object result;
  var calls = 0;

  @override
  Future<EpsTacnaRemoteData> synchronize({
    required String username,
    required String password,
    required DateTime synchronizedAt,
  }) async {
    calls += 1;
    final current = result;
    if (current is Exception) throw current;
    return current as EpsTacnaRemoteData;
  }
}

class _FakeLocal implements WaterLocalStore {
  WaterSnapshot? snapshot;
  var persistCalls = 0;
  var deleteCalls = 0;
  String? failureCode;
  var failPersist = false;

  @override
  Future<WaterSnapshot?> loadLatest(String providerId) async => snapshot;

  @override
  Future<LocalUpsertResult> persistSynchronization({
    required WaterAccount account,
    required List<BillingRecord> billingRecords,
    required List<PaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  }) async {
    persistCalls += 1;
    if (failPersist) throw StateError('test storage failure');
    const result = LocalUpsertResult(
      insertedBillingRecords: 1,
      updatedBillingRecords: 2,
      insertedPaymentRecords: 3,
      updatedPaymentRecords: 4,
    );
    snapshot = WaterSnapshot(
      account: account,
      billingRecords: billingRecords,
      paymentRecords: paymentRecords,
      synchronization: SynchronizationMetadata(
        providerId: account.providerId,
        customerCode: account.customerCode,
        lastAttemptAt: attemptedAt,
        lastSuccessfulSyncAt: attemptedAt,
        status: SynchronizationStatus.success,
        insertedBillingRecords: result.insertedBillingRecords,
        updatedBillingRecords: result.updatedBillingRecords,
        insertedPaymentRecords: result.insertedPaymentRecords,
        updatedPaymentRecords: result.updatedPaymentRecords,
      ),
    );
    return result;
  }

  @override
  Future<void> recordFailure({
    required String providerId,
    required String customerCode,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  }) async {
    failureCode = sanitizedErrorCode;
  }

  @override
  Future<void> deleteProvider(String providerId) async {
    deleteCalls += 1;
    snapshot = null;
  }
}

class _FakeUsernameStore implements RememberedUsernameStore {
  String? value;
  var deleteCalls = 0;
  var failWrite = false;

  @override
  Future<void> delete() async {
    deleteCalls += 1;
    value = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String username) async {
    if (failWrite) throw StateError('secure storage unavailable');
    value = username;
  }
}

class _FakeKeyStore implements DatabaseKeyStore {
  var deleteCalls = 0;

  @override
  Future<void> delete() async => deleteCalls += 1;

  @override
  Future<String> getOrCreate() async => 'KEY-FOR-TEST';
}

class _FakeDatabaseLifecycle implements WaterDatabaseLifecycle {
  var deleteCalls = 0;

  @override
  Future<void> delete() async => deleteCalls += 1;
}

void main() {
  const providerId = 'eps-tacna';
  const customerCode = 'CLIENTE-DE-PRUEBA';
  final now = DateTime.utc(2026, 8, 4, 12);
  final account = WaterAccount(
    providerId: providerId,
    customerCode: customerCode,
    ownerName: 'PERSONA DE PRUEBA',
    synchronizedAt: now,
  );
  final remoteData = EpsTacnaRemoteData(
    account: account,
    billingRecords: const [],
    paymentRecords: const [],
  );

  test('loadLocal never calls the portal', () async {
    final remote = _FakeRemote(remoteData);
    final local = _FakeLocal();
    final repository = EpsTacnaRepository(
      local: local,
      remote: remote,
      usernameStore: _FakeUsernameStore(),
      keyStore: _FakeKeyStore(),
      databaseLifecycle: _FakeDatabaseLifecycle(),
      clock: () => now,
    );

    expect(await repository.loadLocal(), isNull);
    expect(remote.calls, 0);
  });

  test('synchronize persists atomically and remembers only username', () async {
    final remote = _FakeRemote(remoteData);
    final local = _FakeLocal();
    final usernameStore = _FakeUsernameStore();
    final repository = EpsTacnaRepository(
      local: local,
      remote: remote,
      usernameStore: usernameStore,
      keyStore: _FakeKeyStore(),
      databaseLifecycle: _FakeDatabaseLifecycle(),
      clock: () => now,
    );

    final result = await repository.synchronize(
      username: customerCode,
      password: 'CLAVE-EFIMERA-DE-PRUEBA',
    );

    expect(remote.calls, 1);
    expect(local.persistCalls, 1);
    expect(usernameStore.value, customerCode);
    expect(result.insertedBillingRecords, 1);
    expect(result.updatedPaymentRecords, 4);
    expect(result.snapshot.account.ownerName, 'PERSONA DE PRUEBA');
  });

  test(
    'failed synchronization preserves local data and records safe code',
    () async {
      final remote = _FakeRemote(const IncompleteSynchronizationException());
      final local = _FakeLocal()
        ..snapshot = WaterSnapshot(
          account: account,
          billingRecords: const [],
          paymentRecords: const [],
          synchronization: SynchronizationMetadata(
            providerId: providerId,
            customerCode: customerCode,
            lastAttemptAt: now,
            lastSuccessfulSyncAt: now,
            status: SynchronizationStatus.success,
            insertedBillingRecords: 0,
            updatedBillingRecords: 0,
            insertedPaymentRecords: 0,
            updatedPaymentRecords: 0,
          ),
        );
      final before = local.snapshot;
      final repository = EpsTacnaRepository(
        local: local,
        remote: remote,
        usernameStore: _FakeUsernameStore(),
        keyStore: _FakeKeyStore(),
        databaseLifecycle: _FakeDatabaseLifecycle(),
        clock: () => now.add(const Duration(hours: 1)),
      );

      await expectLater(
        repository.synchronize(
          username: customerCode,
          password: 'CLAVE-EFIMERA-DE-PRUEBA',
        ),
        throwsA(isA<IncompleteSynchronizationException>()),
      );

      expect(local.snapshot, same(before));
      expect(local.persistCalls, 0);
      expect(local.failureCode, 'incomplete_synchronization');
    },
  );

  test('optional username failure does not reverse a committed sync', () async {
    final local = _FakeLocal();
    final usernameStore = _FakeUsernameStore()..failWrite = true;
    final repository = EpsTacnaRepository(
      local: local,
      remote: _FakeRemote(remoteData),
      usernameStore: usernameStore,
      keyStore: _FakeKeyStore(),
      databaseLifecycle: _FakeDatabaseLifecycle(),
      clock: () => now,
    );

    final result = await repository.synchronize(
      username: customerCode,
      password: 'CLAVE-EFIMERA-DE-PRUEBA',
    );

    expect(local.persistCalls, 1);
    expect(local.failureCode, isNull);
    expect(result.snapshot.account.customerCode, customerCode);
  });

  test('local persistence failure remains a typed storage error', () async {
    final local = _FakeLocal()..failPersist = true;
    final repository = EpsTacnaRepository(
      local: local,
      remote: _FakeRemote(remoteData),
      usernameStore: _FakeUsernameStore(),
      keyStore: _FakeKeyStore(),
      databaseLifecycle: _FakeDatabaseLifecycle(),
      clock: () => now,
    );

    await expectLater(
      repository.synchronize(
        username: customerCode,
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
      ),
      throwsA(isA<LocalStorageException>()),
    );

    expect(local.failureCode, 'local_storage');
  });

  test('deleteWaterData clears rows, database, username and key', () async {
    final local = _FakeLocal();
    final usernameStore = _FakeUsernameStore()..value = customerCode;
    final keyStore = _FakeKeyStore();
    final lifecycle = _FakeDatabaseLifecycle();
    final repository = EpsTacnaRepository(
      local: local,
      remote: _FakeRemote(remoteData),
      usernameStore: usernameStore,
      keyStore: keyStore,
      databaseLifecycle: lifecycle,
      clock: () => now,
    );

    await repository.deleteWaterData();

    expect(local.deleteCalls, 1);
    expect(lifecycle.deleteCalls, 1);
    expect(usernameStore.deleteCalls, 1);
    expect(keyStore.deleteCalls, 1);
  });
}
