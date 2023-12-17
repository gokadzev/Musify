import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/enums/quality_enum.dart';

class AudioQualityAdapter extends TypeAdapter<AudioQuality> {
  @override
  final int typeId = 1;

  @override
  AudioQuality read(BinaryReader reader) {
    final value = reader.readInt();
    return AudioQuality.values[value];
  }

  @override
  void write(BinaryWriter writer, AudioQuality obj) {
    writer.writeInt(obj.index);
  }
}
