import 'package:freezed_annotation/freezed_annotation.dart';

part 'filesize.freezed.dart';
part 'filesize.g.dart';

/// Encapsulates file size.
@freezed
abstract class FileSize with _$FileSize implements Comparable<FileSize> {
  /// Total kilobytes.
  double get totalKiloBytes => totalBytes / 1024;

  /// Total megabytes.
  double get totalMegaBytes => totalKiloBytes / 1024;

  /// Total gigabytes.
  double get totalGigaBytes => totalMegaBytes / 1024;

  /// Initializes an instance of [FileSize]
  //@With<Comparable<FileSize>>()
  const factory FileSize(
    /// Total bytes.
    int totalBytes,
  ) = _FileSize;

  factory FileSize.fromJson(Map<String, dynamic> json) =>
      _$FileSizeFromJson(json);

  const FileSize._();

  static const FileSize unknown = FileSize(0);

  @override
  int compareTo(FileSize other) => totalBytes.compareTo(other.totalBytes);

  String _getLargestSymbol() {
    if (totalGigaBytes.abs() >= 1) {
      return 'GB';
    }
    if (totalMegaBytes.abs() >= 1) {
      return 'MB';
    }
    if (totalKiloBytes.abs() >= 1) {
      return 'KB';
    }
    return 'B';
  }

  num _getLargestValue() {
    if (totalGigaBytes.abs() >= 1) {
      return totalGigaBytes;
    }
    if (totalMegaBytes.abs() >= 1) {
      return totalMegaBytes;
    }
    if (totalKiloBytes.abs() >= 1) {
      return totalKiloBytes;
    }
    return totalBytes;
  }

  @override
  String toString() =>
      '${_getLargestValue().toStringAsFixed(2)} ${_getLargestSymbol()}';
}
