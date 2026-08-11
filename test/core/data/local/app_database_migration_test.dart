import 'package:consumo_plus/core/data/local/app_database_schema.dart';
import 'package:consumo_plus/features/electricity/data/local/electricity_database_schema.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('fresh schema creates Water and Electricity tables', () async {
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
      ),
    );
    addTearDown(database.close);

    final tables = (await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((row) => row['name']).toSet();

    expect(tables, containsAll(WaterDatabaseSchema.tables));
    expect(tables, containsAll(ElectricityDatabaseSchema.tables));
  });

  test('migration 1 to 2 preserves existing Water rows', () async {
    final factory = databaseFactoryFfiNoIsolate;
    final path = await factory.getDatabasesPath().then(
      (root) => '$root/migration-test.db',
    );
    await factory.deleteDatabase(path);
    addTearDown(() => factory.deleteDatabase(path));

    var database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: WaterDatabaseSchema.create,
      ),
    );
    await database.insert(WaterDatabaseSchema.accounts, {
      'provider_id': 'eps-tacna',
      'customer_code': 'CLIENTE-FICTICIO',
      'owner_name': 'PERSONA FICTICIA',
      'synchronized_at': DateTime.utc(2026, 8, 11).millisecondsSinceEpoch,
    });
    await database.close();

    database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppDatabaseSchema.version,
        onCreate: AppDatabaseSchema.create,
        onUpgrade: AppDatabaseSchema.upgrade,
      ),
    );
    addTearDown(database.close);

    final water = await database.query(WaterDatabaseSchema.accounts);
    final electricity = await database.query(
      ElectricityDatabaseSchema.accounts,
    );
    expect(water.single['customer_code'], 'CLIENTE-FICTICIO');
    expect(electricity, isEmpty);
  });
}
