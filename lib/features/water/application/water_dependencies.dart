import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/features/water/data/local/encrypted_water_database.dart';
import 'package:consumo_plus/features/water/data/local/remembered_username_store.dart';
import 'package:consumo_plus/features/water/data/local/secure_database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_http_client.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_remote_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/io_eps_tacna_transport.dart';
import 'package:consumo_plus/features/water/data/repositories/eps_tacna_repository.dart';

class WaterDependencies {
  WaterDependencies._({
    required SecureValueStore secureStorage,
    required SecureDatabaseKeyStore keyStore,
  }) : _secureStorage = secureStorage,
       _keyStore = keyStore;

  factory WaterDependencies.production() {
    final secureStorage = FlutterSecureValueStore();
    return WaterDependencies._(
      secureStorage: secureStorage,
      keyStore: SecureDatabaseKeyStore(storage: secureStorage),
    );
  }

  final SecureValueStore _secureStorage;
  final SecureDatabaseKeyStore _keyStore;
  EncryptedWaterDatabase? _database;

  Future<WaterViewModel> createViewModel() async {
    final database = _database ??= EncryptedWaterDatabase(_keyStore);
    final sqlDatabase = await database.open();
    final local = WaterLocalDataSource(sqlDatabase);
    final remote = EpsTacnaRemoteDataSource(
      clientFactory: () => EpsTacnaHttpClient(IoEpsTacnaTransport()),
    );
    final repository = EpsTacnaRepository(
      local: local,
      remote: remote,
      usernameStore: SecureRememberedUsernameStore(_secureStorage),
      keyStore: _keyStore,
      databaseLifecycle: database,
    );
    return WaterViewModel(repository: repository);
  }

  Future<void> dispose() async {
    await _database?.close();
  }
}
