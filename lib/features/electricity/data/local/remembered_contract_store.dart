import 'package:consumo_plus/core/data/local/secure_database_key_store.dart';

abstract interface class RememberedContractStore {
  Future<String?> read();

  Future<void> write(String contractNumber);

  Future<void> delete();
}

class SecureRememberedContractStore implements RememberedContractStore {
  SecureRememberedContractStore(this._storage);

  static const _key = 'electrosur_remembered_contract_v1';

  final SecureValueStore _storage;

  @override
  Future<String?> read() => _storage.read(_key);

  @override
  Future<void> write(String contractNumber) =>
      _storage.write(_key, contractNumber);

  @override
  Future<void> delete() => _storage.delete(_key);
}
