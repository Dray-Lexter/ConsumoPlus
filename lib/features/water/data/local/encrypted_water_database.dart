import 'dart:io';

import 'package:consumo_plus/features/water/data/local/database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

abstract interface class WaterDatabaseLifecycle {
  Future<void> delete();
}

class EncryptedWaterDatabase implements WaterDatabaseLifecycle {
  EncryptedWaterDatabase(this._keyStore);

  static const fileName = 'consumo_plus_water.db';

  final DatabaseKeyStore _keyStore;
  Database? _database;
  Future<Database>? _opening;

  Future<Database> open() async {
    final existing = _database;
    if (existing != null && existing.isOpen) return existing;

    final pending = _opening;
    if (pending != null) return pending;
    final opening = _openDatabase();
    _opening = opening;
    try {
      return await opening;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _openDatabase() async {
    final password = await _keyStore.getOrCreate();
    final root = await getDatabasesPath();
    final path = '$root${Platform.pathSeparator}$fileName';
    final database = await openDatabase(
      path,
      password: password,
      version: WaterDatabaseSchema.version,
      onCreate: WaterDatabaseSchema.create,
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await opening;
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) await database.close();
  }

  @override
  Future<void> delete() async {
    await close();
    final root = await getDatabasesPath();
    final path = '$root${Platform.pathSeparator}$fileName';
    await deleteDatabase(path);
  }
}
