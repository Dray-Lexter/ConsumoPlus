import 'package:consumo_plus/features/water/application/water_view_model.dart';
import 'package:consumo_plus/core/data/local/encrypted_app_database.dart';
import 'package:consumo_plus/core/data/local/secure_database_key_store.dart';
import 'package:consumo_plus/features/water/data/local/remembered_username_store.dart';
import 'package:consumo_plus/features/water/data/local/water_local_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_http_client.dart';
import 'package:consumo_plus/features/water/data/remote/eps_tacna_remote_data_source.dart';
import 'package:consumo_plus/features/water/data/remote/io_eps_tacna_transport.dart';
import 'package:consumo_plus/features/water/data/repositories/eps_tacna_repository.dart';

class WaterDependencies {
  const WaterDependencies.shared({
    required SecureValueStore secureStorage,
    required EncryptedAppDatabase database,
  }) : _secureStorage = secureStorage,
       _database = database;

  final SecureValueStore _secureStorage;
  final EncryptedAppDatabase _database;

  Future<WaterViewModel> createViewModel() async {
    final sqlDatabase = await _database.open();
    final local = WaterLocalDataSource(sqlDatabase);
    final remote = EpsTacnaRemoteDataSource(
      clientFactory: () => EpsTacnaHttpClient(IoEpsTacnaTransport()),
    );
    final repository = EpsTacnaRepository(
      local: local,
      remote: remote,
      usernameStore: SecureRememberedUsernameStore(_secureStorage),
    );
    return WaterViewModel(repository: repository);
  }
}
