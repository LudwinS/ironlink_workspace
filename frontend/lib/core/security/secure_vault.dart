import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureVault {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(), // Windows native DPAPI encryption
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';

  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  static Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);
  static Future<String?> getUsername() async => await _storage.read(key: _usernameKey);
  static Future<String?> getEmail() async => await _storage.read(key: _emailKey);
  static Future<String?> getRole() async => await _storage.read(key: _roleKey);

  static Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _roleKey);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
