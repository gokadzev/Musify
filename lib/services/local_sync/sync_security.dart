import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'package:musify/services/local_sync/sync_data.dart';

class SyncSecurity {
  static final _cipher = AesGcm.with256bits();
  static String randomToken([int length = 32]) {
    final random = Random.secure();
    return base64UrlEncode(List.generate(length, (_) => random.nextInt(256)));
  }

  static Future<Map<String, dynamic>> seal(
    String secret,
    Map<String, dynamic> body,
    String context,
  ) async {
    final box = await _cipher.encrypt(
      utf8.encode(canonicalSync(body)),
      secretKey: SecretKey(base64Url.decode(secret)),
      aad: utf8.encode(context),
    );
    return {
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  static Future<Map<String, dynamic>> open(
    String secret,
    Map box,
    String context,
  ) async {
    final nonce = base64Decode(box['nonce'] as String);
    final mac = base64Decode(box['mac'] as String);
    if (nonce.length != 12 || mac.length != 16)
      throw const FormatException('Invalid encrypted message');
    final clear = await _cipher.decrypt(
      SecretBox(
        base64Decode(box['ciphertext'] as String),
        nonce: nonce,
        mac: Mac(mac),
      ),
      secretKey: SecretKey(base64Url.decode(secret)),
      aad: utf8.encode(context),
    );
    final value = jsonDecode(utf8.decode(clear));
    if (value is! Map) throw const FormatException('Invalid encrypted body');
    validateSyncJson(value);
    return Map<String, dynamic>.from(value);
  }
}
