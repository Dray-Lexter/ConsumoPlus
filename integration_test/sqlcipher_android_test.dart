import 'dart:io';

import 'package:consumo_plus/features/water/data/local/database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/encrypted_water_database.dart';
import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class _FixedKeyStore implements DatabaseKeyStore {
  const _FixedKeyStore(this.value);
  final String value;

  @override
  Future<void> delete() async {}

  @override
  Future<String> getOrCreate() async => value;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SQLCipher rejects an absent or incorrect key on Android', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    const correctKey = 'INTEGRATION-ONLY-RANDOM-LIKE-KEY-32';
    final encrypted = EncryptedWaterDatabase(const _FixedKeyStore(correctKey));
    await encrypted.delete();
    final database = await encrypted.open();
    await database.query(WaterDatabaseSchema.accounts);
    await encrypted.close();

    final root = await getDatabasesPath();
    final path =
        '$root${Platform.pathSeparator}${EncryptedWaterDatabase.fileName}';
    await _expectUnreadable(path, password: 'INCORRECT-INTEGRATION-KEY');
    await _expectUnreadable(path);

    await encrypted.delete();
  });
}

Future<void> _expectUnreadable(String path, {String? password}) async {
  Database? database;
  var rejected = false;
  try {
    database = password == null
        ? await openDatabase(path)
        : await openDatabase(path, password: password);
    await database.query(WaterDatabaseSchema.accounts);
  } on Object {
    rejected = true;
  } finally {
    await database?.close();
  }
  expect(
    rejected,
    isTrue,
    reason: 'Encrypted data must reject a missing or wrong key.',
  );
}
