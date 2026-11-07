/*
 *     Copyright (C) 2026 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

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
    final clear = utf8.encode(jsonEncode(body));
    // The receiver applies the limit after decompressing.
    if (clear.length > maxSyncMessageBytes) throw const SyncTooLargeException();
    // Compressing first keeps the pure-Dart cipher fast on large libraries.
    final box = await _cipher.encrypt(
      gzip.encode(clear),
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
    if (nonce.length != 12 || mac.length != 16) {
      throw const FormatException('Invalid encrypted message');
    }
    final clear = await _cipher.decrypt(
      SecretBox(
        base64Decode(box['ciphertext'] as String),
        nonce: nonce,
        mac: Mac(mac),
      ),
      secretKey: SecretKey(base64Url.decode(secret)),
      aad: utf8.encode(context),
    );
    final value = jsonDecode(utf8.decode(_inflate(clear)));
    if (value is! Map) throw const FormatException('Invalid encrypted body');
    validateSyncJson(value);
    return Map<String, dynamic>.from(value);
  }

  /// [seal] on another isolate: compressing and encrypting a whole library
  /// takes long enough to freeze the interface.
  static Future<Map<String, dynamic>> sealInBackground(
    String secret,
    Map<String, dynamic> body,
    String context,
  ) => Isolate.run(() => seal(secret, body, context));

  /// [open] on another isolate, for the same reason.
  static Future<Map<String, dynamic>> openInBackground(
    String secret,
    Map box,
    String context,
  ) => Isolate.run(() => open(secret, box, context));

  /// Reads the JSON envelope of a request and [open]s it, all on another
  /// isolate: decoding up to 64 MB of JSON before knowing who sent it would
  /// freeze the interface of the receiving device. The bytes move to the other
  /// isolate without being copied.
  static Future<Map<String, dynamic>> openRequestInBackground(
    String secret,
    Uint8List request,
    String context, {
    required int apiVersion,
  }) {
    final transferable = TransferableTypedData.fromList([request]);
    return Isolate.run(() async {
      final decoded = jsonDecode(
        utf8.decode(transferable.materialize().asUint8List()),
      );
      if (decoded is! Map) throw const SyncEnvelopeException();
      if (decoded['apiVersion'] != apiVersion) {
        throw const SyncEnvelopeException(upgradeRequired: true);
      }
      final box = decoded['encrypted'];
      if (box is! Map) throw const SyncEnvelopeException();
      return open(secret, box, context);
    });
  }

  static List<int> _inflate(List<int> compressed) {
    final output = _CappedSink();
    gzip.decoder.startChunkedConversion(output)
      ..add(compressed)
      ..close();
    return output.bytes.takeBytes();
  }
}

/// Stops a compressed message from expanding beyond the sync size limit.
class _CappedSink implements Sink<List<int>> {
  final bytes = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    bytes.add(chunk);
    if (bytes.length > maxSyncMessageBytes) throw const SyncTooLargeException();
  }

  @override
  void close() {}
}

/// A request whose envelope is not what the protocol sends.
class SyncEnvelopeException implements Exception {
  const SyncEnvelopeException({this.upgradeRequired = false});

  /// The sender speaks another version of the protocol.
  final bool upgradeRequired;
}
