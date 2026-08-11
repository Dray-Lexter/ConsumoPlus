import 'package:flutter/foundation.dart';

import '../domain/errors/water_exceptions.dart';
import '../domain/models/synchronization_result.dart';
import '../domain/models/water_snapshot.dart';
import '../domain/repositories/water_repository.dart';
import 'water_state.dart';

class WaterViewModel extends ChangeNotifier {
  WaterViewModel({
    required WaterRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  final WaterRepository _repository;
  final DateTime Function() _clock;

  WaterState _state = const WaterState();
  var _disposed = false;
  WaterState get state => _state;

  Future<void> initialize() async {
    _setState(_state.copyWith(status: WaterStatus.loadingLocal));
    try {
      final results = await Future.wait<Object?>([
        _repository.loadLocal(),
        _repository.loadRememberedUsername(),
      ]);
      final snapshot = results[0] as WaterSnapshot?;
      final rememberedUsername = results[1] as String?;
      _setState(
        WaterState(
          status: snapshot == null ? WaterStatus.empty : WaterStatus.data,
          snapshot: snapshot,
          rememberedUsername: rememberedUsername,
          shouldRecommendUpdate: _shouldRecommendUpdate(snapshot),
        ),
      );
    } on WaterException catch (error) {
      _setSafeError(error.userMessage);
    } catch (_) {
      _setSafeError(
        'No pudimos abrir tus datos guardados. Intenta nuevamente.',
      );
    }
  }

  Future<void> synchronize({
    required String username,
    required String password,
  }) async {
    _setState(
      _state.copyWith(
        status: WaterStatus.synchronizing,
        errorMessage: null,
        syncSummary: null,
      ),
    );

    try {
      final result = await _repository.synchronize(
        username: username,
        password: password,
      );
      _setState(
        WaterState(
          status: WaterStatus.data,
          snapshot: result.snapshot,
          rememberedUsername: username,
          shouldRecommendUpdate: false,
          syncSummary: _buildSyncSummary(result),
        ),
      );
    } on WaterException catch (error) {
      _setSafeError(error.userMessage);
    } catch (_) {
      _setSafeError(
        'No pudimos actualizar tus datos. La información anterior se conservó.',
      );
    }
  }

  Future<void> deleteWaterData() async {
    _setState(_state.copyWith(status: WaterStatus.deleting));
    try {
      await _repository.deleteWaterData();
      _setState(const WaterState(status: WaterStatus.empty));
    } on WaterException catch (error) {
      _setSafeError(error.userMessage);
    } catch (_) {
      _setSafeError('No pudimos borrar los datos de Agua. Intenta nuevamente.');
    }
  }

  bool _shouldRecommendUpdate(WaterSnapshot? snapshot) {
    final lastSync = snapshot?.synchronization.lastSuccessfulSyncAt?.toLocal();
    if (lastSync == null) return false;
    final now = _clock();
    return lastSync.year != now.year || lastSync.month != now.month;
  }

  String _buildSyncSummary(SynchronizationResult result) {
    final parts = <String>[];
    if (result.insertedBillingRecords > 0) {
      parts.add(
        '${result.insertedBillingRecords} ${result.insertedBillingRecords == 1 ? 'recibo nuevo' : 'recibos nuevos'}',
      );
    }
    if (result.updatedBillingRecords > 0) {
      parts.add(
        '${result.updatedBillingRecords} ${result.updatedBillingRecords == 1 ? 'actualizado' : 'actualizados'}',
      );
    }
    if (result.insertedPaymentRecords > 0) {
      parts.add(
        '${result.insertedPaymentRecords} ${result.insertedPaymentRecords == 1 ? 'pago nuevo' : 'pagos nuevos'}',
      );
    }
    if (result.updatedPaymentRecords > 0) {
      parts.add(
        '${result.updatedPaymentRecords} ${result.updatedPaymentRecords == 1 ? 'pago actualizado' : 'pagos actualizados'}',
      );
    }
    if (parts.isEmpty) return 'Tus datos ya estaban al dia.';
    return '${parts.join(', ')}.';
  }

  void _setSafeError(String message) {
    _setState(
      _state.copyWith(status: WaterStatus.error, errorMessage: message),
    );
  }

  void _setState(WaterState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  String toString() => 'WaterViewModel(state: $_state)';
}
