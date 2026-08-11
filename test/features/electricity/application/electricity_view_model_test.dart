import 'package:consumo_plus/features/electricity/application/electricity_state.dart';
import 'package:consumo_plus/features/electricity/application/electricity_view_model.dart';
import 'package:consumo_plus/features/electricity/domain/errors/electricity_exceptions.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_result.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/repositories/electricity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data/repositories/electrosur_repository_test.dart' show remoteData;

class _FakeRepository implements ElectricityRepository {
  ElectricitySnapshot? local;
  String? remembered;
  Object? syncResult;
  var synchronizeCalls = 0;
  var deleted = false;

  @override
  Future<ElectricitySnapshot?> loadLocal() async => local;
  @override
  Future<String?> loadRememberedContract() async => remembered;
  @override
  Future<ElectricitySynchronizationResult> synchronize({
    required String contractNumber,
    required String password,
  }) async {
    synchronizeCalls += 1;
    final result = syncResult;
    if (result is Exception) throw result;
    return result! as ElectricitySynchronizationResult;
  }

  @override
  Future<void> deleteElectricityData() async => deleted = true;
}

void main() {
  final now = DateTime.utc(2026, 8, 11, 14);

  test('initialize is local-first and does not call remote sync', () async {
    final repository = _FakeRepository()..remembered = 'CONTRATO-FICTICIO-001';
    final viewModel = ElectricityViewModel(repository: repository);

    await viewModel.initialize();

    expect(viewModel.state.status, ElectricityStatus.empty);
    expect(viewModel.state.rememberedContract, 'CONTRATO-FICTICIO-001');
    expect(repository.synchronizeCalls, 0);
  });

  test('synchronize exposes data and a safe update summary', () async {
    final data = remoteData(now);
    final snapshot = ElectricitySnapshot(
      account: data.account,
      accountStatuses: [data.accountStatus],
      consumptionRecords: data.consumptionRecords,
      paymentRecords: data.paymentRecords,
      synchronization: ElectricitySynchronizationMetadata(
        providerId: 'electrosur',
        contractNumber: 'CONTRATO-FICTICIO-001',
        lastAttemptAt: now,
        lastSuccessfulSyncAt: now,
        status: ElectricitySynchronizationStatus.success,
        insertedConsumptionRecords: 1,
        updatedConsumptionRecords: 0,
        insertedPaymentRecords: 0,
        updatedPaymentRecords: 0,
        accountStatusUpdated: true,
        supplyDetailsUpdated: true,
      ),
    );
    // Build through the repository result helper to keep the state test focused.
    final repository = _FakeRepository();
    repository.syncResult = ElectricitySynchronizationResult(
      snapshot: snapshot,
      insertedConsumptionRecords: 1,
      updatedConsumptionRecords: 0,
      insertedPaymentRecords: 0,
      updatedPaymentRecords: 0,
      accountStatusUpdated: true,
      supplyDetailsUpdated: true,
    );
    final viewModel = ElectricityViewModel(repository: repository);

    await viewModel.synchronize(
      contractNumber: 'CONTRATO-FICTICIO-001',
      password: 'CLAVE-EFIMERA-FICTICIA',
    );

    expect(viewModel.state.status, ElectricityStatus.data);
    expect(viewModel.state.syncSummary, contains('consumo nuevo'));
  });

  test(
    'a failed refresh keeps previous data visible with typed message',
    () async {
      final repository = _FakeRepository()
        ..syncResult = const ElectrosurUnavailableException();
      final viewModel = ElectricityViewModel(repository: repository);

      await viewModel.synchronize(
        contractNumber: 'CONTRATO-FICTICIO-001',
        password: 'CLAVE-EFIMERA-FICTICIA',
      );

      expect(viewModel.state.status, ElectricityStatus.error);
      expect(viewModel.state.errorMessage, contains('Electrosur'));
    },
  );
}
