abstract interface class DatabaseKeyStore {
  static const waterKeyName = 'water_database_key_v1';

  Future<String> getOrCreate();

  Future<void> delete();
}
