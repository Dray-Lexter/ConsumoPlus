import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'database_key_store.dart';

typedef RandomBytes = List<int> Function(int length);

abstract interface class SecureValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureValueStore implements SecureValueStore {
  FlutterSecureValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureDatabaseKeyStore implements DatabaseKeyStore {
  SecureDatabaseKeyStore({
    required SecureValueStore storage,
    RandomBytes? randomBytes,
  }) : _storage = storage,
       _randomBytes = randomBytes ?? _secureRandomBytes;

  final SecureValueStore _storage;
  final RandomBytes _randomBytes;
  Future<String>? _pendingKey;

  @override
  Future<String> getOrCreate() async {
    final pending = _pendingKey;
    if (pending != null) return pending;
    final operation = _loadOrCreate();
    _pendingKey = operation;
    try {
      return await operation;
    } catch (_) {
      if (identical(_pendingKey, operation)) _pendingKey = null;
      rethrow;
    }
  }

  Future<String> _loadOrCreate() async {
    final existing = await _storage.read(DatabaseKeyStore.databaseKeyName);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = base64UrlEncode(_randomBytes(32));
    await _storage.write(DatabaseKeyStore.databaseKeyName, generated);
    return generated;
  }

  @override
  Future<void> delete() async {
    final pending = _pendingKey;
    if (pending != null) await pending;
    await _storage.delete(DatabaseKeyStore.databaseKeyName);
    _pendingKey = null;
  }

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  @override
  String toString() => 'SecureDatabaseKeyStore(configured: true)';
}
