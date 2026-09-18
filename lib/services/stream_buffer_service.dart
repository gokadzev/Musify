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

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:just_audio/just_audio.dart';
import 'package:musify/constants/clients.dart';
import 'package:musify/main.dart';
import 'package:musify/services/io_service.dart';
import 'package:musify/services/proxy_manager.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// How long a read waits on bytes that never arrive before it gives up, so a
/// dead connection surfaces as a playback error instead of silence.
const _readStallTimeout = Duration(seconds: 30);

/// How often a read looks for bytes the download hasn't written yet.
const _readPollInterval = Duration(milliseconds: 50);

/// How much is handed to the player at a time.
const _readChunkSize = 64 * 1024;

/// Whether songs play through a buffer file. Turning it off puts playback back
/// on the plain streaming path, where the player fetches the stream URL itself
/// and nothing is written to disk.
bool get streamBufferEnabled => streamBufferSupport.value;

/// Clears whatever a previous run left behind. The buffer of a song is dropped
/// as soon as the next one starts, but a crash or a kill mid-song leaves its
/// file there, and nothing ever plays it again.
Future<void> clearStreamBuffers() async {
  try {
    final directory = Directory(FilePaths.getStreamBufferDirPath());
    if (!await directory.exists()) return;

    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      try {
        await entity.delete();
      } catch (e, stackTrace) {
        logger.log(
          'Error clearing buffer ${entity.path}',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  } catch (e, stackTrace) {
    logger.log(
      'Error clearing stream buffers',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

/// Plays a song out of a file that fills up as it plays.
///
/// The bytes are fetched the way an offline download fetches them, in ranged
/// chunks, which YouTube serves far faster than the single long request the
/// player makes on its own for a stream URL. The file therefore runs ahead of
/// playback within seconds, and a slow moment on the network stops being
/// audible.
///
/// The file is a buffer, not a library: it is dropped as soon as another song
/// takes over. Keeping a song for later is what the offline download is for,
/// and that is the user's decision to make, not a side effect of pressing
/// play.
// just_audio still marks its byte-serving source API experimental. It is the
// only way to feed the player from something other than a URL or a finished
// file, so the warning is accepted here rather than worked around.
// ignore: experimental_member_use
class BufferedStreamAudioSource extends StreamAudioSource {
  BufferedStreamAudioSource({
    required this.songId,
    required this.streamInfo,
    super.tag,
  }) : bufferFile = File(
         '${FilePaths.getStreamBufferDirPath()}/$songId.part',
       );

  /// The download feeding the song being played. Starting another one discards
  /// it: skipping through a queue would otherwise leave a download running per
  /// song passed through, all competing for the same connection.
  static BufferedStreamAudioSource? _active;

  final String songId;
  final AudioOnlyStreamInfo streamInfo;
  final File bufferFile;

  Future<void>? _download;
  RandomAccessFile? _writeHandle;
  int _downloadedBytes = 0;
  bool _downloadDone = false;
  bool _discarded = false;
  Object? _downloadError;

  int get _totalBytes => streamInfo.size.totalBytes;

  @override
  // ignore: experimental_member_use
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    _ensureDownloadStarted();

    final from = start ?? 0;
    final to = end ?? _totalBytes;

    // ignore: experimental_member_use
    return StreamAudioResponse(
      sourceLength: _totalBytes,
      contentLength: to - from,
      offset: from,
      stream: _read(from, to),
      contentType: streamInfo.codec.mimeType,
    );
  }

  /// Stops the download and drops the buffer file. Called when another song
  /// takes over, which is the only thing this file was ever kept for.
  Future<void> discard() async {
    if (_discarded) return;
    _discarded = true;

    await _download;

    try {
      await _writeHandle?.close();
    } catch (_) {}
    _writeHandle = null;

    try {
      if (await bufferFile.exists()) await bufferFile.delete();
    } catch (e, stackTrace) {
      logger.log(
        'Error discarding buffer for $songId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _ensureDownloadStarted() {
    if (_download != null) return;

    final previous = _active;
    if (previous != null && previous != this) {
      unawaited(previous.discard());
    }
    _active = this;

    _download = _runDownload();
  }

  Future<void> _runDownload() async {
    try {
      await Directory(FilePaths.getStreamBufferDirPath()).create(
        recursive: true,
      );

      final handle = await bufferFile.open(mode: FileMode.write);
      _writeHandle = handle;

      final chunks = ytClient.videos.streamsClient.get(
        streamInfo,
        ytClient: customClients.first,
      );

      // Returning from the loop cancels the underlying subscription, which is
      // how a discarded download stops pulling bytes.
      await for (final chunk in chunks) {
        if (_discarded) return;
        await handle.writeFrom(chunk);
        _downloadedBytes += chunk.length;
      }

      await handle.flush();
    } catch (e, stackTrace) {
      _downloadError = e;
      logger.log(
        'Error buffering stream for $songId',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _downloadDone = true;
      // The write handle stays open, and the file on disk: the song is still
      // playing out of it. Both go in discard(), when the next song starts.
    }
  }

  Stream<List<int>> _read(int from, int to) async* {
    var position = from;
    var waited = Duration.zero;
    RandomAccessFile? handle;

    try {
      while (position < to) {
        if (_discarded) return;
        if (_downloadError != null) {
          throw Exception('Stream buffer failed for $songId: $_downloadError');
        }

        final available = _downloadedBytes - position;
        if (available <= 0) {
          // Nothing more is coming: the player has everything there is.
          if (_downloadDone) return;
          if (waited >= _readStallTimeout) {
            throw TimeoutException('Stream buffer stalled for $songId');
          }
          await Future<void>.delayed(_readPollInterval);
          waited += _readPollInterval;
          continue;
        }

        waited = Duration.zero;
        handle ??= await bufferFile.open();
        await handle.setPosition(position);

        final bytes = await handle.read(
          min(min(available, to - position), _readChunkSize),
        );
        if (bytes.isEmpty) {
          await Future<void>.delayed(_readPollInterval);
          continue;
        }

        position += bytes.length;
        yield bytes;
      }
    } finally {
      try {
        await handle?.close();
      } catch (_) {}
    }
  }
}
