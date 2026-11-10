import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();
  Future<void> deleteAccessToken();
  Future<void> deleteRefreshToken();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth.access_token';
  static const _refreshKey = 'auth.refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  @override
  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  @override
  Future<void> deleteAccessToken() => _storage.delete(key: _accessKey);

  @override
  Future<void> deleteRefreshToken() => _storage.delete(key: _refreshKey);

  @override
  Future<void> clear() => _storage.deleteAll();
}
