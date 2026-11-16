import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// Encrypts health data before it is written to the device database
/// (AES-256-GCM, key kept in platform secure storage).
class DataCipher {
  DataCipher(this._key);

  final SecretKey _key;
  static final _algorithm = AesGcm.with256bits();

  static Future<DataCipher> fromBase64(String? stored, Future<void> Function(String) persist) async {
    if (stored != null) return DataCipher(SecretKey(base64Decode(stored)));
    final key = await _algorithm.newSecretKey();
    await persist(base64Encode(await key.extractBytes()));
    return DataCipher(key);
  }

  Future<String> encrypt(String plain) async {
    final box = await _algorithm.encrypt(utf8.encode(plain), secretKey: _key);
    return base64Encode(box.concatenation());
  }

  Future<String> decrypt(String encoded) async {
    final box = SecretBox.fromConcatenation(
      base64Decode(encoded),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return utf8.decode(await _algorithm.decrypt(box, secretKey: _key));
  }
}
