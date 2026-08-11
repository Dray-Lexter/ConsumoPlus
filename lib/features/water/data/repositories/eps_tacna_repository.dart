import 'package:consumo_plus/features/water/data/local/remembered_username_store.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_remote_data_source.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_result.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/domain/repositories/water_repository.dart';

class EpsTacnaRepository implements WaterRepository {
  EpsTacnaRepository({
    required WaterLocalStore local,
    required EpsTacnaRemoteSource remote,
    required RememberedUsernameStore usernameStore,
    DateTime Function()? clock,
  }) : _local = local,
       _remote = remote,
       _usernameStore = usernameStore,
       _clock = clock ?? DateTime.now;

  static const providerId = EpsTacnaRemoteDataSource.providerId;

  final WaterLocalStore _local;
  final EpsTacnaRemoteSource _remote;
  final RememberedUsernameStore _usernameStore;
  final DateTime Function() _clock;

  @override
  Future<WaterSnapshot?> loadLocal() => _local.loadLatest(providerId);

  @override
  Future<String?> loadRememberedUsername() => _usernameStore.read();

  @override
  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  }) async {
    final attemptedAt = _clock();
    try {
      final remote = await _remote.synchronize(
        username: username,
        password: password,
        synchronizedAt: attemptedAt,
      );
      late final LocalUpsertResult counts;
      try {
        counts = await _local.persistSynchronization(
          account: remote.account,
          billingRecords: remote.billingRecords,
          paymentRecords: remote.paymentRecords,
          attemptedAt: attemptedAt,
        );
      } on Object {
        throw const LocalStorageException();
      }
      try {
        await _usernameStore.write(username);
      } on Object {
        // The database transaction is already definitive. Remembering the
        // non-secret username is optional and must not turn it into a failure.
      }
      final snapshot = WaterSnapshot(
        account: remote.account,
        billingRecords: remote.billingRecords,
        paymentRecords: remote.paymentRecords,
        synchronization: SynchronizationMetadata(
          providerId: remote.account.providerId,
          customerCode: remote.account.customerCode,
          lastAttemptAt: attemptedAt,
          lastSuccessfulSyncAt: attemptedAt,
          status: SynchronizationStatus.success,
          insertedBillingRecords: counts.insertedBillingRecords,
          updatedBillingRecords: counts.updatedBillingRecords,
          insertedPaymentRecords: counts.insertedPaymentRecords,
          updatedPaymentRecords: counts.updatedPaymentRecords,
        ),
      );
      return SynchronizationResult(
        snapshot: snapshot,
        insertedBillingRecords: counts.insertedBillingRecords,
        updatedBillingRecords: counts.updatedBillingRecords,
        insertedPaymentRecords: counts.insertedPaymentRecords,
        updatedPaymentRecords: counts.updatedPaymentRecords,
      );
    } on WaterException catch (error) {
      await _local.recordFailure(
        providerId: providerId,
        customerCode: username,
        attemptedAt: attemptedAt,
        sanitizedErrorCode: error.sanitizedCode,
      );
      rethrow;
    } on Object {
      const error = IncompleteSynchronizationException();
      await _local.recordFailure(
        providerId: providerId,
        customerCode: username,
        attemptedAt: attemptedAt,
        sanitizedErrorCode: error.sanitizedCode,
      );
      throw error;
    }
  }

  @override
  Future<void> deleteWaterData() async {
    await _local.deleteProvider(providerId);
    await _usernameStore.delete();
  }
}
