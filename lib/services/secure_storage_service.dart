import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<Map<String, String>> readAll() async {
    return _storage.readAll();
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}

/// Key constants for secure storage.
class StorageKeys {
  static const String pendingName = 'pending_name';
  static const String pendingPhone = 'pending_phone';
  static const String pendingPasswordHash = 'pending_password_hash';
  static const String pendingVerificationId = 'pending_verification_id';
  static const String pendingResendToken = 'pending_resend_token';
  static const String pendingLoginUid = 'pending_login_uid';
}