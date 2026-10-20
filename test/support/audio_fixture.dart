import 'dart:typed_data';

Uint8List silentWav({int size = 32000}) {
  final bytes = ByteData(44 + size);
  void text(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      bytes.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  text(8, 'WAVE');
  text(12, 'fmt ');
  text(36, 'data');
  bytes
    ..setUint32(4, 36 + size, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 8000, Endian.little)
    ..setUint32(28, 16000, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(40, size, Endian.little);
  return bytes.buffer.asUint8List();
}
