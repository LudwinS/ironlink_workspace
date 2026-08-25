import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureVault {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(), // Windows native DPAPI encryption
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';

  // In-memory cache to prevent DPAPI registry write latency on immediate reads
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static String? _cachedUsername;
  static String? _cachedEmail;
  static String? _cachedRole;
  static String? _cachedUserId;
  static bool? _cachedRememberMe;

  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String username,
    required String email,
    required String role,
    required String userId,
    bool rememberMe = false,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedUsername = username;
    _cachedEmail = email;
    _cachedRole = role;
    _cachedUserId = userId;
    _cachedRememberMe = rememberMe;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _usernameKey, value: username),
      _storage.write(key: _emailKey, value: email),
      _storage.write(key: _roleKey, value: role),
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _rememberMeKey, value: rememberMe ? 'true' : 'false'),
    ]);
  }

  static Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final token = await _storage.read(key: _accessTokenKey);
    _cachedAccessToken = token;
    return token;
  }

  static Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    final token = await _storage.read(key: _refreshTokenKey);
    _cachedRefreshToken = token;
    return token;
  }

  static Future<String?> getUsername() async {
    if (_cachedUsername != null) return _cachedUsername;
    final val = await _storage.read(key: _usernameKey);
    _cachedUsername = val;
    return val;
  }

  static Future<String?> getEmail() async {
    if (_cachedEmail != null) return _cachedEmail;
    final val = await _storage.read(key: _emailKey);
    _cachedEmail = val;
    return val;
  }

  static Future<String?> getRole() async {
    if (_cachedRole != null) return _cachedRole;
    final val = await _storage.read(key: _roleKey);
    _cachedRole = val;
    return val;
  }

  static Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    final val = await _storage.read(key: _userIdKey);
    _cachedUserId = val;
    return val;
  }

  static Future<bool> getRememberMe() async {
    if (_cachedRememberMe != null) return _cachedRememberMe!;
    final val = await _storage.read(key: _rememberMeKey);
    _cachedRememberMe = val == 'true';
    return _cachedRememberMe!;
  }

  static Future<void> clearAuthData() async {
    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedUsername = null;
    _cachedEmail = null;
    _cachedRole = null;
    _cachedUserId = null;
    _cachedRememberMe = null;

    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _usernameKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _roleKey),
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _rememberMeKey),
    ]);
  }

  static Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
