abstract interface class DatabaseKeyStore {
  // The stored key name is intentionally unchanged so existing installations
  // can open their database after the schema becomes shared by both services.
  static const databaseKeyName = 'water_database_key_v1';
  static const waterKeyName = databaseKeyName;

  Future<String> getOrCreate();

  Future<void> delete();
}
