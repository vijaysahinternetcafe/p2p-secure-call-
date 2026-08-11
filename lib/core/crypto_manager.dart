import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class CryptoManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    ),
    iOptions: IOSOptions(
      accountName: 'flutter_secure_storage_service',
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _keyPairKey = 'device_keypair';
  static const _deviceIdKey = 'device_id';

  SimpleKeyPair? _keyPair;
  String? _deviceId;

  String get deviceId => _deviceId ?? 'unknown';

  Future<void> initialize() async {
    _deviceId = await _storage.read(key: _deviceIdKey);
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: _deviceId);
    }

    final storedKeys = await _storage.read(key: _keyPairKey);
    if (storedKeys != null) {
      final keyData = base64Decode(storedKeys);
      _keyPair = await Ed25519().newKeyPairFromSeed(keyData.sublist(0, 32));
    } else {
      _keyPair = await Ed25519().newKeyPair();
      final seed = await _keyPair!.extractPrivateKeyBytes();
      await _storage.write(key: _keyPairKey, value: base64Encode(seed));
    }
  }

  Future<String> sign(String message) async {
    if (_keyPair == null) throw Exception('Crypto not initialized');
    final signature = await Ed25519().sign(
      utf8.encode(message),
      keyPair: _keyPair!,
    );
    return base64Encode(signature.bytes);
  }

  Future<String> getPublicKey() async {
    if (_keyPair == null) throw Exception('Crypto not initialized');
    final pubKey = await _keyPair!.extractPublicKey();
    return base64Encode(pubKey.bytes);
  }

  Future<Map<String, dynamic>> exportKeys() async {
    return {
      'deviceId': _deviceId,
      'publicKey': await getPublicKey(),
    };
  }
}
