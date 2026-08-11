import 'package:consumo_plus/core/config/service_providers.dart';
import 'package:consumo_plus/core/data/local/encrypted_app_database.dart';
import 'package:consumo_plus/features/electricity/data/local/electricity_local_data_source.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';

import 'local_upcoming_dates_source.dart';
import 'forecast_controller.dart';
import 'local_forecast_source.dart';
import 'upcoming_dates_controller.dart';

class HomeDependencies {
  const HomeDependencies.shared({required EncryptedAppDatabase database})
    : _database = database;

  final EncryptedAppDatabase _database;

  Future<UpcomingDatesController> createUpcomingDatesController() async {
    final database = await _database.open();
    final water = WaterLocalDataSource(database);
    final electricity = ElectricityLocalDataSource(database);
    return UpcomingDatesController(
      source: LocalUpcomingDatesSource(
        loadWater: () => water.loadLatest(epsTacnaProvider.id),
        loadElectricity: () => electricity.loadLatest(electrosurProvider.id),
      ),
    );
  }

  Future<ForecastController> createForecastController() async {
    final database = await _database.open();
    final water = WaterLocalDataSource(database);
    final electricity = ElectricityLocalDataSource(database);
    return ForecastController(
      source: LocalForecastSource(
        loadWater: () => water.loadLatest(epsTacnaProvider.id),
        loadElectricity: () => electricity.loadLatest(electrosurProvider.id),
      ),
    );
  }
}
