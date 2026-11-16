import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/core/database/data_cipher.dart';

void main() {
  test('encrypts and decrypts with a persisted key', () async {
    String? stored;
    final cipher = await DataCipher.fromBase64(null, (k) async => stored = k);
    final secret = await cipher.encrypt('{"value":7}');
    expect(secret, isNot(contains('value')));

    final reopened = await DataCipher.fromBase64(stored, (_) async {});
    expect(await reopened.decrypt(secret), '{"value":7}');
  });

  test('uses a fresh nonce for every encryption', () async {
    final cipher = await DataCipher.fromBase64(null, (_) async {});
    expect(await cipher.encrypt('same'), isNot(await cipher.encrypt('same')));
  });
}
