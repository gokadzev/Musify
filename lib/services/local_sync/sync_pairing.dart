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
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dsrp/dsrp.dart' as srp;

// RFC 5054, appendix A.3. Both sides pin the group instead of trusting the LAN.
final _prime = BigInt.parse(
  'AC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC319294'
  '3DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310D'
  'CD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FB'
  'D5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF74'
  '7359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A'
  '436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D'
  '5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E73'
  '03CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB6'
  '94B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F'
  '9E4AFF73',
  radix: 16,
);
final _generator = BigInt.two;

Uint8List _decode(Object? raw, int maxBytes, {int? exactBytes}) {
  if (raw is! String || raw.length > ((maxBytes + 2) ~/ 3) * 4) {
    throw const FormatException('Invalid pairing proof');
  }
  final bytes = base64Decode(raw);
  if (bytes.isEmpty ||
      bytes.length > maxBytes ||
      (exactBytes != null && bytes.length != exactBytes)) {
    throw const FormatException('Invalid pairing proof');
  }
  return bytes;
}

Future<String> _secret(Uint8List key, String context) async {
  final derived = await Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
    secretKey: SecretKey(key),
    nonce: utf8.encode(context),
    info: utf8.encode('Musify PIN pairing v3'),
  );
  return base64UrlEncode(await derived.extractBytes());
}

class PinPairingReceiver {
  PinPairingReceiver._(this.pin, this.context, this._server, this.challenge);
  final String pin;
  final String context;
  final srp.Server _server;
  final Map<String, dynamic> challenge;
  bool _used = false;

  static Future<PinPairingReceiver> create(String context) async {
    final pin = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
    final verifier = await srp.User.createSaltedVerificationKeyFromBytes(
      userIdBytes: Uint8List.fromList(utf8.encode(context)),
      passwordBytes: Uint8List.fromList(utf8.encode(pin)),
      generator: _generator,
      safePrime: _prime,
      kdf: srp.KdfChoice.sha256,
    );
    final server = srp.Server(
      userId: context,
      salt: verifier.salt,
      verifierKey: verifier.key,
      generator: _generator,
      safePrime: _prime,
      hashFunction: srp.HashFunctionChoice.sha256,
    );
    final challenge = await server.createChallenge();
    return PinPairingReceiver._(pin, context, server, {
      'publicKey': base64Encode(challenge.ephemeralServerPublicKey),
      'salt': base64Encode(challenge.verifierKeySalt),
    });
  }

  Future<({String secret, String proof})> verify(Map proof) async {
    if (_used) throw const FormatException('Pairing challenge already used');
    _used = true;
    final reply = await _server.verifySession(
      ephemeralUserPublicKey: _decode(proof['publicKey'], 256),
      userSessionKeyVerifier: _decode(proof['verifier'], 32, exactBytes: 32),
    );
    return (
      secret: await _secret(_server.sessionKey!, context),
      proof: base64Encode(reply),
    );
  }
}

class PinPairingClient {
  PinPairingClient._(this._user, this.context);
  final srp.User _user;
  final String context;

  static Future<PinPairingClient> create(
    Map challenge,
    String context,
    String pin,
  ) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('Invalid PIN');
    }
    final user = await srp.User.fromUserCredsBytesAndChallenge(
      userIdBytes: Uint8List.fromList(utf8.encode(context)),
      passwordBytes: Uint8List.fromList(utf8.encode(pin)),
      challenge: srp.Challenge.fromServer(
        generator: _generator,
        safePrime: _prime,
        ephemeralServerPublicKey: _decode(challenge['publicKey'], 256),
        verifierKeySalt: _decode(challenge['salt'], 32, exactBytes: 32),
        hashFunctionChoice: srp.HashFunctionChoice.sha256,
      ),
      kdf: srp.KdfChoice.sha256,
    );
    return PinPairingClient._(user, context);
  }

  Map<String, dynamic> proof() {
    final proof = _user.getUserSessionVerifiers();
    return {
      'publicKey': base64Encode(proof.ephemeralUserPublicKey),
      'verifier': base64Encode(proof.sessionKeyVerifier),
    };
  }

  Future<String> verify(Object? proof) async {
    await _user.verifySession(_decode(proof, 32, exactBytes: 32));
    return _secret(_user.sessionKey, context);
  }
}
