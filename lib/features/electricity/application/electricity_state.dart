import '../domain/models/electricity_snapshot.dart';

enum ElectricityStatus {
  initial,
  loadingLocal,
  empty,
  data,
  synchronizing,
  error,
  deleting,
}

class ElectricityState {
  const ElectricityState({
    this.status = ElectricityStatus.initial,
    this.snapshot,
    this.rememberedContract,
    this.shouldRecommendUpdate = false,
    this.errorMessage,
    this.syncSummary,
  });

  static const _unchanged = Object();

  final ElectricityStatus status;
  final ElectricitySnapshot? snapshot;
  final String? rememberedContract;
  final bool shouldRecommendUpdate;
  final String? errorMessage;
  final String? syncSummary;

  ElectricityState copyWith({
    ElectricityStatus? status,
    Object? snapshot = _unchanged,
    Object? rememberedContract = _unchanged,
    bool? shouldRecommendUpdate,
    Object? errorMessage = _unchanged,
    Object? syncSummary = _unchanged,
  }) {
    return ElectricityState(
      status: status ?? this.status,
      snapshot: identical(snapshot, _unchanged)
          ? this.snapshot
          : snapshot as ElectricitySnapshot?,
      rememberedContract: identical(rememberedContract, _unchanged)
          ? this.rememberedContract
          : rememberedContract as String?,
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
}
