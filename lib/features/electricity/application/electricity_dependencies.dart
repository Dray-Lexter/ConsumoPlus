import 'package:consumo_plus/features/electricity/application/electricity_view_model.dart';
import 'package:consumo_plus/features/electricity/data/local/electricity_local_data_source.dart';
import 'package:consumo_plus/features/electricity/data/local/remembered_contract_store.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_http_client.dart';
import 'package:consumo_plus/features/electricity/data/remote/electrosur_remote_data_source.dart';
import 'package:consumo_plus/features/electricity/data/remote/io_electrosur_transport.dart';
import 'package:consumo_plus/features/electricity/data/repositories/electrosur_repository.dart';
import 'package:consumo_plus/core/data/local/encrypted_app_database.dart';
import 'package:consumo_plus/core/data/local/secure_database_key_store.dart';

class ElectricityDependencies {
  const ElectricityDependencies.shared({
    required SecureValueStore secureStorage,
    required EncryptedAppDatabase database,
  }) : _secureStorage = secureStorage,
       _database = database;

  final SecureValueStore _secureStorage;
  final EncryptedAppDatabase _database;

  Future<ElectricityViewModel> createViewModel() async {
    final sqlDatabase = await _database.open();
    final repository = ElectrosurRepository(
      local: ElectricityLocalDataSource(sqlDatabase),
      remote: ElectrosurRemoteDataSource(
        clientFactory: () => ElectrosurHttpClient(IoElectrosurTransport()),
      ),
      contractStore: SecureRememberedContractStore(_secureStorage),
    );
    return ElectricityViewModel(repository: repository);
  }
}
