import '../models/electricity_snapshot.dart';
import '../models/electricity_synchronization_result.dart';

abstract interface class ElectricityRepository {
  Future<ElectricitySnapshot?> loadLocal();

  Future<String?> loadRememberedContract();

  Future<ElectricitySynchronizationResult> synchronize({
    required String contractNumber,
    required String password,
  });

  Future<void> deleteElectricityData();
}
