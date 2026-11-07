import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_pairing.dart';
import 'package:musify/services/local_sync/sync_security.dart';

void main() {
  test(
    'typing the receiver PIN authenticates both devices without approval',
    () async {
      final receiver = await PinPairingReceiver.create('A|B|session');
      final client = await PinPairingClient.create(
        receiver.challenge,
        'A|B|session',
        receiver.pin,
      );
      expect(receiver.challenge.toString(), isNot(contains(receiver.pin)));
      final agreement = await receiver.verify(client.proof());
      expect(await client.verify(agreement.proof), agreement.secret);
    },
  );
  test('incorrect PIN and changed peer context cannot authenticate', () async {
    for (final changedContext in [false, true]) {
      final receiver = await PinPairingReceiver.create('A|B|session');
      final wrongPin = receiver.pin == '000000' ? '000001' : '000000';
      final client = await PinPairingClient.create(
        receiver.challenge,
        changedContext ? 'A|attacker|session' : 'A|B|session',
        changedContext ? receiver.pin : wrongPin,
      );
      await expectLater(receiver.verify(client.proof()), throwsA(anything));
    }
  });
  test(
    'one-use challenge and invalid public keys cannot establish trust',
    () async {
      final receiver = await PinPairingReceiver.create('A|B|session');
      await expectLater(
        receiver.verify({'publicKey': 'AA==', 'verifier': 'AA=='}),
        throwsA(anything),
      );
      final client = await PinPairingClient.create(
        receiver.challenge,
        'A|B|session',
        receiver.pin,
      );
      await expectLater(receiver.verify(client.proof()), throwsFormatException);
    },
  );
  test('encrypted library round-trips and cannot be read with another key or route', () async {
    final key = SyncSecurity.randomToken();
    final box = await SyncSecurity.seal(key, {
      'song': 'private',
      'requestId': 'nonce',
    }, 'merge|A|B');
    expect(box.toString(), isNot(contains('private')));
    expect((await SyncSecurity.open(key, box, 'merge|A|B'))['song'], 'private');
    await expectLater(
      SyncSecurity.open(SyncSecurity.randomToken(), box, 'merge|A|B'),
      throwsA(anything),
    );
    await expectLater(
      SyncSecurity.open(key, box, 'confirm|A|B'),
      throwsA(anything),
    );
    await expectLater(
      SyncSecurity.open(key, {
        ...box,
        'mac': 'AAAAAAAAAAAAAAAAAAAAAA==',
      }, 'merge|A|B'),
      throwsA(anything),
    );
  });
  test(
    'oversized messages are refused before sending and after inflating',
    () async {
      final key = SyncSecurity.randomToken();
      final huge = {'padding': List.filled(65 * 1024 * 1024, 'a').join()};
      await expectLater(
        SyncSecurity.seal(key, huge, 'merge|A|B'),
        throwsA(isA<SyncTooLargeException>()),
      );
      final box = await AesGcm.with256bits().encrypt(
        gzip.encode(utf8.encode(jsonEncode(huge))),
        secretKey: SecretKey(base64Url.decode(key)),
        aad: utf8.encode('merge|A|B'),
      );
      await expectLater(
        SyncSecurity.open(key, {
          'nonce': base64Encode(box.nonce),
          'ciphertext': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        }, 'merge|A|B'),
        throwsA(isA<SyncTooLargeException>()),
      );
    },
  );
}
