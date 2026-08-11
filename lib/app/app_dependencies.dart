import 'package:consumo_plus/features/electricity/application/electricity_dependencies.dart';
import 'package:consumo_plus/features/electricity/application/electricity_view_model.dart';
import 'package:consumo_plus/features/home/application/home_dependencies.dart';
import 'package:consumo_plus/features/home/application/forecast_controller.dart';
import 'package:consumo_plus/features/home/application/upcoming_dates_controller.dart';
import 'package:consumo_plus/features/water/application/water_dependencies.dart';
import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/core/data/local/encrypted_app_database.dart';
import 'package:consumo_plus/core/data/local/secure_database_key_store.dart';

class AppDependencies {
  AppDependencies._({
    required HomeDependencies home,
    required WaterDependencies water,
    required ElectricityDependencies electricity,
    required EncryptedAppDatabase database,
  }) : _home = home,
       _water = water,
       _electricity = electricity,
       _database = database;

  factory AppDependencies.production() {
    final secureStorage = FlutterSecureValueStore();
    final keyStore = SecureDatabaseKeyStore(storage: secureStorage);
    final database = EncryptedAppDatabase(keyStore);
    return AppDependencies._(
      home: HomeDependencies.shared(database: database),
      water: WaterDependencies.shared(
        secureStorage: secureStorage,
        database: database,
      ),
      electricity: ElectricityDependencies.shared(
        secureStorage: secureStorage,
        database: database,
      ),
      database: database,
    );
  }

  final HomeDependencies _home;
  final WaterDependencies _water;
  final ElectricityDependencies _electricity;
  final EncryptedAppDatabase _database;

  Future<UpcomingDatesController> createUpcomingDatesController() =>
      _home.createUpcomingDatesController();

  Future<ForecastController> createForecastController() =>
      _home.createForecastController();

  Future<WaterViewModel> createWaterViewModel() => _water.createViewModel();

  Future<ElectricityViewModel> createElectricityViewModel() =>
      _electricity.createViewModel();

  Future<void> dispose() => _database.close();
}
