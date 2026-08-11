import 'dart:async';

import 'package:consumo_plus/features/water/application/water_state.dart';
import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/features/water/domain/errors/water_exceptions.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_result.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:consumo_plus/features/water/domain/repositories/water_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements WaterRepository {
  WaterSnapshot? local;
  String? rememberedUsername;
  Object? synchronization;
  var loadCalls = 0;
  var synchronizeCalls = 0;
  var deleteCalls = 0;
  String? receivedUsername;
  String? receivedPassword;

  @override
  Future<WaterSnapshot?> loadLocal() async {
    loadCalls += 1;
    return local;
  }

  @override
  Future<String?> loadRememberedUsername() async => rememberedUsername;

  @override
  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  }) async {
    synchronizeCalls += 1;
    receivedUsername = username;
    receivedPassword = password;
    final value = synchronization;
    if (value is Exception) throw value;
    return value! as SynchronizationResult;
  }

  @override
  Future<void> deleteWaterData() async {
    deleteCalls += 1;
    local = null;
    rememberedUsername = null;
  }
}

class _DelayedRepository extends _FakeRepository {
  final completer = Completer<SynchronizationResult>();

  @override
  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  }) => completer.future;
}

WaterSnapshot snapshot(DateTime synchronizedAt) {
  return WaterSnapshot(
    account: WaterAccount(
      providerId: 'eps-tacna',
      customerCode: 'CLIENTE-DE-PRUEBA',
      ownerName: 'PERSONA DE PRUEBA',
      synchronizedAt: synchronizedAt,
    ),
    billingRecords: const [],
    paymentRecords: const [],
    synchronization: SynchronizationMetadata(
      providerId: 'eps-tacna',
      customerCode: 'CLIENTE-DE-PRUEBA',
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

void main() {
  final now = DateTime(2026, 8, 4, 12);

  test('initialize loads local data and never scrapes automatically', () async {
    final repository = _FakeRepository()
      ..local = snapshot(now)
      ..rememberedUsername = 'CLIENTE-DE-PRUEBA';
    final viewModel = WaterViewModel(repository: repository, clock: () => now);

    await viewModel.initialize();

    expect(repository.loadCalls, 1);
    expect(repository.synchronizeCalls, 0);
    expect(viewModel.state.status, WaterStatus.data);
    expect(viewModel.state.snapshot, same(repository.local));
    expect(viewModel.state.rememberedUsername, 'CLIENTE-DE-PRUEBA');
    expect(viewModel.state.shouldRecommendUpdate, isFalse);
  });

  test('empty local storage becomes an honest empty state', () async {
    final repository = _FakeRepository();
    final viewModel = WaterViewModel(repository: repository, clock: () => now);

    await viewModel.initialize();

    expect(viewModel.state.status, WaterStatus.empty);
    expect(viewModel.state.snapshot, isNull);
  });

  test(
    'manual synchronization returns counts without retaining password',
    () async {
      const password = 'CLAVE-EFIMERA-DE-PRUEBA';
      final synced = snapshot(now);
      final repository = _FakeRepository()
        ..synchronization = SynchronizationResult(
          snapshot: synced,
          insertedBillingRecords: 2,
          updatedBillingRecords: 1,
          insertedPaymentRecords: 3,
          updatedPaymentRecords: 0,
        );
      final viewModel = WaterViewModel(
        repository: repository,
        clock: () => now,
      );

      await viewModel.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: password,
      );

      expect(repository.receivedPassword, password);
      expect(viewModel.state.status, WaterStatus.data);
      expect(
        viewModel.state.syncSummary,
        '2 recibos nuevos, 1 actualizado, 3 pagos nuevos.',
      );
      expect(viewModel.state.toString(), isNot(contains(password)));
      expect(viewModel.toString(), isNot(contains(password)));
    },
  );

  test('synchronization error keeps local snapshot and safe message', () async {
    final previous = snapshot(now.subtract(const Duration(days: 30)));
    final repository = _FakeRepository()
      ..local = previous
      ..synchronization = const NetworkTimeoutException();
    final viewModel = WaterViewModel(repository: repository, clock: () => now);
    await viewModel.initialize();

    await viewModel.synchronize(
      username: 'CLIENTE-DE-PRUEBA',
      password: 'CLAVE-EFIMERA-DE-PRUEBA',
    );

    expect(viewModel.state.status, WaterStatus.error);
    expect(viewModel.state.snapshot, same(previous));
    expect(
      viewModel.state.errorMessage,
      const NetworkTimeoutException().userMessage,
    );
  });

  test(
    'post-login parser error is presented as synchronization failure',
    () async {
      final repository = _FakeRepository()
        ..synchronization = const BillingHistoryStructureException();
      final viewModel = WaterViewModel(
        repository: repository,
        clock: () => now,
      );

      await viewModel.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
      );

      expect(viewModel.state.status, WaterStatus.error);
      expect(
        viewModel.state.errorMessage,
        const BillingHistoryStructureException().userMessage,
      );
      expect(
        viewModel.state.errorMessage,
        isNot(const InvalidCredentialsException().userMessage),
      );
    },
  );

  test('a previous month recommends a manual update', () async {
    final repository = _FakeRepository()
      ..local = snapshot(DateTime(2026, 7, 30));
    final viewModel = WaterViewModel(repository: repository, clock: () => now);

    await viewModel.initialize();

    expect(viewModel.state.shouldRecommendUpdate, isTrue);
  });

  test('delete clears visible state and remembered username', () async {
    final repository = _FakeRepository()
      ..local = snapshot(now)
      ..rememberedUsername = 'CLIENTE-DE-PRUEBA';
    final viewModel = WaterViewModel(repository: repository, clock: () => now);
    await viewModel.initialize();

    await viewModel.deleteWaterData();

    expect(repository.deleteCalls, 1);
    expect(viewModel.state.status, WaterStatus.empty);
    expect(viewModel.state.snapshot, isNull);
    expect(viewModel.state.rememberedUsername, isNull);
  });

  test(
    'completion after dispose does not notify a disposed view model',
    () async {
      final repository = _DelayedRepository();
      final viewModel = WaterViewModel(
        repository: repository,
        clock: () => now,
      );
      final operation = viewModel.synchronize(
        username: 'CLIENTE-DE-PRUEBA',
        password: 'CLAVE-EFIMERA-DE-PRUEBA',
      );
      viewModel.dispose();

      repository.completer.complete(
        SynchronizationResult(
          snapshot: snapshot(now),
          insertedBillingRecords: 0,
          updatedBillingRecords: 0,
          insertedPaymentRecords: 0,
          updatedPaymentRecords: 0,
        ),
      );

      await expectLater(operation, completes);
    },
  );
}
