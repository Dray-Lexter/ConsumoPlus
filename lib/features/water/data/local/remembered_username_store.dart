import 'package:consumo_plus/features/water/data/local/secure_database_key_store.dart';

abstract interface class RememberedUsernameStore {
  Future<String?> read();

  Future<void> write(String username);

  Future<void> delete();
}

class SecureRememberedUsernameStore implements RememberedUsernameStore {
  SecureRememberedUsernameStore(this._storage);

  static const _key = 'eps_tacna_remembered_username_v1';

  final SecureValueStore _storage;

  @override
  Future<String?> read() => _storage.read(_key);

  @override
  Future<void> write(String username) => _storage.write(_key, username);

  @override
  Future<void> delete() => _storage.delete(_key);
}
