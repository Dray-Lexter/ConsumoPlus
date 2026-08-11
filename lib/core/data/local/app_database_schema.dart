import 'package:consumo_plus/features/electricity/data/local/electricity_database_schema.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:sqflite_common/sqlite_api.dart';

abstract final class AppDatabaseSchema {
  static const version = 2;

  static Future<void> create(Database database, int version) async {
    await WaterDatabaseSchema.create(database, version);
    await ElectricityDatabaseSchema.create(database);
  }

  static Future<void> upgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await ElectricityDatabaseSchema.create(database);
    }
  }
}
