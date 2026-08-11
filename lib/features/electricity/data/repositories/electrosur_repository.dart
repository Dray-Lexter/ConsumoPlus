import 'package:consumo_plus/features/electricity/data/local/electricity_local_data_source.dart';
import 'package:consumo_plus/features/electricity/data/local/remembered_contract_store.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_remote_data_source.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_result.dart';
import 'package:consumo_plus/features/electricity/domain/repositories/electricity_repository.dart';

class ElectrosurRepository implements ElectricityRepository {
  ElectrosurRepository({
    required ElectricityLocalStore local,
    required ElectrosurRemoteSource remote,
    required RememberedContractStore contractStore,
    DateTime Function()? clock,
  }) : _local = local,
       _remote = remote,
       _contractStore = contractStore,
       _clock = clock ?? DateTime.now;

  static const providerId = ElectrosurRemoteDataSource.providerId;

  final ElectricityLocalStore _local;
  final ElectrosurRemoteSource _remote;
  final RememberedContractStore _contractStore;
  final DateTime Function() _clock;

  @override
  Future<ElectricitySnapshot?> loadLocal() => _local.loadLatest(providerId);

  @override
  Future<String?> loadRememberedContract() => _contractStore.read();

  @override
  Future<ElectricitySynchronizationResult> synchronize({
    required String contractNumber,
    required String password,
  }) async {
    final attemptedAt = _clock();
    try {
      final remote = await _remote.synchronize(
        contractNumber: contractNumber,
        password: password,
        synchronizedAt: attemptedAt,
      );
      late final ElectricityLocalUpsertResult counts;
      try {
        counts = await _local.persistSynchronization(
          account: remote.account,
          accountStatus: remote.accountStatus,
          consumptionRecords: remote.consumptionRecords,
          paymentRecords: remote.paymentRecords,
          attemptedAt: attemptedAt,
        );
      } on Object {
        throw const ElectricityLocalStorageException();
      }
      try {
        await _contractStore.write(remote.account.contractNumber);
      } on Object {
        // Remembering a non-secret contract is optional after a definitive
        // database transaction.
      }
      final snapshot = ElectricitySnapshot(
        account: remote.account,
        accountStatuses: [remote.accountStatus],
        consumptionRecords: remote.consumptionRecords,
        paymentRecords: remote.paymentRecords,
        synchronization: ElectricitySynchronizationMetadata(
          providerId: remote.account.providerId,
          contractNumber: remote.account.contractNumber,
          lastAttemptAt: attemptedAt,
          lastSuccessfulSyncAt: attemptedAt,
          status: ElectricitySynchronizationStatus.success,
          insertedConsumptionRecords: counts.insertedConsumptionRecords,
          updatedConsumptionRecords: counts.updatedConsumptionRecords,
          insertedPaymentRecords: counts.insertedPaymentRecords,
          updatedPaymentRecords: counts.updatedPaymentRecords,
          accountStatusUpdated: counts.accountStatusUpdated,
          supplyDetailsUpdated: counts.supplyDetailsUpdated,
        ),
      );
      return ElectricitySynchronizationResult(
        snapshot: snapshot,
        insertedConsumptionRecords: counts.insertedConsumptionRecords,
        updatedConsumptionRecords: counts.updatedConsumptionRecords,
        insertedPaymentRecords: counts.insertedPaymentRecords,
        updatedPaymentRecords: counts.updatedPaymentRecords,
        accountStatusUpdated: counts.accountStatusUpdated,
        supplyDetailsUpdated: counts.supplyDetailsUpdated,
      );
    } on ElectricityException catch (error) {
      await _recordFailure(contractNumber, attemptedAt, error.sanitizedCode);
      rethrow;
    } on Object {
      const error = ElectricityIncompleteSynchronizationException();
      await _recordFailure(contractNumber, attemptedAt, error.sanitizedCode);
      throw error;
    }
  }

  Future<void> _recordFailure(
    String contractNumber,
    DateTime attemptedAt,
    String sanitizedCode,
  ) async {
    try {
      await _local.recordFailure(
        providerId: providerId,
        contractNumber: contractNumber,
        attemptedAt: attemptedAt,
        sanitizedErrorCode: sanitizedCode,
      );
    } on Object {
      // Failure metadata is best-effort and must not hide the original error.
    }
  }

  @override
  Future<void> deleteElectricityData() async {
    await _local.deleteProvider(providerId);
    await _contractStore.delete();
  }
}
