import 'package:flutter/foundation.dart';

import '../domain/errors/electricity_exceptions.dart';
import '../domain/models/electricity_snapshot.dart';
import '../domain/models/electricity_synchronization_result.dart';
import '../domain/repositories/electricity_repository.dart';
import 'electricity_state.dart';

class ElectricityViewModel extends ChangeNotifier {
  ElectricityViewModel({
    required ElectricityRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final ElectricityRepository _repository;
  final DateTime Function() _clock;
  ElectricityState _state = const ElectricityState();
  var _disposed = false;

  ElectricityState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(status: ElectricityStatus.loadingLocal));
    try {
      final results = await Future.wait<Object?>([
        _repository.loadLocal(),
        _repository.loadRememberedContract(),
      ]);
      final snapshot = results[0] as ElectricitySnapshot?;
      final rememberedContract = results[1] as String?;
      _setState(
        ElectricityState(
          status: snapshot == null
              ? ElectricityStatus.empty
              : ElectricityStatus.data,
          snapshot: snapshot,
          rememberedContract: rememberedContract,
          shouldRecommendUpdate: _shouldRecommendUpdate(snapshot),
        ),
      );
    } on Object {
      _setSafeError(
        'No pudimos abrir tus datos guardados. Intenta nuevamente.',
      );
    }
  }

  Future<void> synchronize({
    required String contractNumber,
    required String password,
  }) async {
    _setState(
      _state.copyWith(
        status: ElectricityStatus.synchronizing,
        errorMessage: null,
        syncSummary: null,
      ),
    );
    try {
      final result = await _repository.synchronize(
        contractNumber: contractNumber,
        password: password,
      );
      _setState(
        ElectricityState(
          status: ElectricityStatus.data,
          snapshot: result.snapshot,
          rememberedContract: contractNumber,
          syncSummary: _buildSyncSummary(result),
        ),
      );
    } on ElectricityException catch (error) {
      _setSafeError(error.userMessage);
    } on Object {
      _setSafeError(
        'No pudimos actualizar tus datos. La información anterior se conservó.',
      );
    }
  }

  Future<void> deleteElectricityData() async {
    _setState(_state.copyWith(status: ElectricityStatus.deleting));
    try {
      await _repository.deleteElectricityData();
      _setState(const ElectricityState(status: ElectricityStatus.empty));
    } on Object {
      _setSafeError(
        'No pudimos borrar los datos de Electricidad. Intenta nuevamente.',
      );
    }
  }

  bool _shouldRecommendUpdate(ElectricitySnapshot? snapshot) {
    final lastSync = snapshot?.synchronization.lastSuccessfulSyncAt?.toLocal();
    if (lastSync == null) return false;
    final now = _clock();
    return lastSync.year != now.year || lastSync.month != now.month;
  }

  static String _buildSyncSummary(ElectricitySynchronizationResult result) {
    final parts = <String>[];
    if (result.insertedConsumptionRecords > 0) {
      parts.add(
        '${result.insertedConsumptionRecords} '
        '${result.insertedConsumptionRecords == 1 ? 'consumo nuevo' : 'consumos nuevos'}',
      );
    }
    if (result.updatedConsumptionRecords > 0) {
      parts.add('${result.updatedConsumptionRecords} consumos actualizados');
    }
    if (result.insertedPaymentRecords > 0) {
      parts.add(
        '${result.insertedPaymentRecords} '
        '${result.insertedPaymentRecords == 1 ? 'pago nuevo' : 'pagos nuevos'}',
      );
    }
    if (result.updatedPaymentRecords > 0) {
      parts.add('${result.updatedPaymentRecords} pagos actualizados');
    }
    if (parts.isEmpty &&
        !result.accountStatusUpdated &&
        !result.supplyDetailsUpdated) {
      return 'Tus datos ya estaban al día.';
    }
    if (parts.isEmpty) return 'Resumen y suministro actualizados.';
    return '${parts.join(', ')}.';
  }

  void _setSafeError(String message) {
    _setState(
      _state.copyWith(status: ElectricityStatus.error, errorMessage: message),
    );
  }

  void _setState(ElectricityState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
