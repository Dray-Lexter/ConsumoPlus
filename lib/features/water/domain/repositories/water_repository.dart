import '../models/synchronization_result.dart';
import '../models/water_snapshot.dart';

abstract interface class WaterRepository {
  Future<WaterSnapshot?> loadLocal();

  Future<String?> loadRememberedUsername();

  Future<SynchronizationResult> synchronize({
    required String username,
    required String password,
  });

  Future<void> deleteWaterData();
}
