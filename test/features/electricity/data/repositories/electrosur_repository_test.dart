import 'package:consumo_plus/features/electricity/data/local/electricity_local_data_source.dart';
import 'package:consumo_plus/features/electricity/data/local/remembered_contract_store.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_remote_data_source.dart';
import 'package:consumo_plus/features/electricity/data/repositories/electrosur_repository.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeLocal implements ElectricityLocalStore {
  ElectricitySnapshot? snapshot;
  var deleted = false;
  String? failureCode;
  ElectricityAccount? persistedAccount;

  @override
  Future<ElectricitySnapshot?> loadLatest(String providerId) async => snapshot;

  @override
  Future<ElectricityLocalUpsertResult> persistSynchronization({
    required ElectricityAccount account,
    required ElectricityAccountStatus accountStatus,
    required List<ElectricityConsumptionRecord> consumptionRecords,
    required List<ElectricityPaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  }) async {
    persistedAccount = account;
    return const ElectricityLocalUpsertResult(
      insertedConsumptionRecords: 2,
      updatedConsumptionRecords: 0,
      insertedPaymentRecords: 1,
      updatedPaymentRecords: 0,
      accountStatusUpdated: true,
      supplyDetailsUpdated: true,
    );
  }

  @override
  Future<void> recordFailure({
    required String providerId,
    required String contractNumber,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  }) async => failureCode = sanitizedErrorCode;

  @override
  Future<void> deleteProvider(String providerId) async => deleted = true;
}

class _FakeRemote implements ElectrosurRemoteSource {
  _FakeRemote(this.result);
  final Object result;

  @override
  Future<ElectrosurRemoteData> synchronize({
    required String contractNumber,
    required String password,
    required DateTime synchronizedAt,
  }) async {
    if (result is Exception) throw result;
    return result as ElectrosurRemoteData;
  }
}

class _FakeContractStore implements RememberedContractStore {
  String? value;
  var deleted = false;

  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String contractNumber) async => value = contractNumber;
  @override
  Future<void> delete() async {
    value = null;
    deleted = true;
  }
}

ElectrosurRemoteData remoteData(DateTime at) {
  const provider = 'electrosur';
  const contract = 'CONTRATO-FICTICIO-001';
  return ElectrosurRemoteData(
    account: ElectricityAccount(
      providerId: provider,
      contractNumber: contract,
      ownerName: 'PERSONA FICTICIA',
      serviceAddress: 'AVENIDA FICTICIA 100',
      tariffCode: 'BT5B-FICTICIA',
      synchronizedAt: at,
    ),
    accountStatus: ElectricityAccountStatus(
      providerId: provider,
      contractNumber: contract,
      billingYear: 2026,
      billingMonth: 7,
      sourcePeriodCode: '202607',
      currentBillingCents: 12345,
      previousDebtCents: 1000,
      totalDebtCents: 13345,
      amountPaidCents: 2000,
      totalBalanceCents: 11345,
      synchronizedAt: at,
    ),
    consumptionRecords: [
      ElectricityConsumptionRecord(
        providerId: provider,
        contractNumber: contract,
        billingYear: 2026,
        billingMonth: 7,
        sourcePeriodCode: '202607',
        tariffCode: 'BT5B-FICTICIA',
        consumptionWh: 340000,
        monthlyChargeCents: 12345,
        synchronizedAt: at,
      ),
    ],
    paymentRecords: const [],
    supplyDetailsAvailable: true,
  );
}

void main() {
  final now = DateTime.utc(2026, 8, 11, 14);

  test(
    'repository synchronizes atomically and remembers only contract',
    () async {
      final local = _FakeLocal();
      final contractStore = _FakeContractStore();
      final repository = ElectrosurRepository(
        local: local,
        remote: _FakeRemote(remoteData(now)),
        contractStore: contractStore,
        clock: () => now,
      );

      final result = await repository.synchronize(
        contractNumber: 'CONTRATO-FICTICIO-001',
        password: 'CLAVE-EFIMERA-FICTICIA',
      );

      expect(result.snapshot.account.contractNumber, 'CONTRATO-FICTICIO-001');
      expect(result.insertedConsumptionRecords, 2);
      expect(local.persistedAccount, isNotNull);
      expect(contractStore.value, 'CONTRATO-FICTICIO-001');
    },
  );

  test('typed remote failure records only sanitized code', () async {
    final local = _FakeLocal();
    final repository = ElectrosurRepository(
      local: local,
      remote: _FakeRemote(const ElectricitySessionExpiredException()),
      contractStore: _FakeContractStore(),
      clock: () => now,
    );

    await expectLater(
      repository.synchronize(
        contractNumber: 'CONTRATO-FICTICIO-001',
        password: 'CLAVE-EFIMERA-FICTICIA',
      ),
      throwsA(isA<ElectricitySessionExpiredException>()),
    );
    expect(local.failureCode, 'session_expired');
  });

  test(
    'deletion removes only electricity local data and remembered contract',
    () async {
      final local = _FakeLocal();
      final store = _FakeContractStore()..value = 'CONTRATO-FICTICIO-001';
      final repository = ElectrosurRepository(
        local: local,
        remote: _FakeRemote(remoteData(now)),
        contractStore: store,
      );

      await repository.deleteElectricityData();

      expect(local.deleted, isTrue);
      expect(store.deleted, isTrue);
    },
  );
}
