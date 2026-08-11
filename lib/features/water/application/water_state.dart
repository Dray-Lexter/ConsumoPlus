import '../domain/models/water_snapshot.dart';

enum WaterStatus {
  initial,
  loadingLocal,
  empty,
  data,
  synchronizing,
  error,
  deleting,
}

class WaterState {
  const WaterState({
    this.status = WaterStatus.initial,
    this.snapshot,
    this.rememberedUsername,
    this.shouldRecommendUpdate = false,
    this.errorMessage,
    this.syncSummary,
  });

  static const _unchanged = Object();

  final WaterStatus status;
  final WaterSnapshot? snapshot;
  final String? rememberedUsername;
  final bool shouldRecommendUpdate;
  final String? errorMessage;
  final String? syncSummary;

  WaterState copyWith({
    WaterStatus? status,
    Object? snapshot = _unchanged,
    Object? rememberedUsername = _unchanged,
    bool? shouldRecommendUpdate,
    Object? errorMessage = _unchanged,
    Object? syncSummary = _unchanged,
  }) {
    return WaterState(
      status: status ?? this.status,
      snapshot: identical(snapshot, _unchanged)
          ? this.snapshot
          : snapshot as WaterSnapshot?,
      rememberedUsername: identical(rememberedUsername, _unchanged)
          ? this.rememberedUsername
          : rememberedUsername as String?,
      shouldRecommendUpdate:
          shouldRecommendUpdate ?? this.shouldRecommendUpdate,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
      syncSummary: identical(syncSummary, _unchanged)
          ? this.syncSummary
          : syncSummary as String?,
    );
  }

  @override
  String toString() {
    return 'WaterState(status: $status, hasSnapshot: ${snapshot != null}, '
        'hasRememberedUsername: ${rememberedUsername != null}, '
        'shouldRecommendUpdate: $shouldRecommendUpdate, '
        'errorMessage: $errorMessage, syncSummary: $syncSummary)';
  }
}
