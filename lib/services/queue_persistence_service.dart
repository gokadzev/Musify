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

import 'package:hive/hive.dart';
import 'package:musify/main.dart' show logger;
import 'package:musify/services/data_manager.dart';
import 'package:musify/utilities/map_utils.dart';

final queuePersistenceService = QueuePersistenceService();

/// The queue as the last session left it.
class PersistedQueue {
  const PersistedQueue({
    required this.queue,
    required this.originalQueue,
    required this.index,
    required this.position,
  });

  final List<Map<String, dynamic>> queue;

  /// The pre-shuffle order, empty unless shuffle was on when it was stored.
  final List<Map<String, dynamic>> originalQueue;
  final int index;
  final Duration position;
}

/// Keeps the playing queue on disk so the next launch can pick it up where the
/// last one left off.
///
/// Songs and playback position are stored apart on purpose: the song list is
/// only rewritten when it actually changes, while the position is rewritten
/// every few seconds of playback and has to stay cheap.
class QueuePersistenceService {
  static const String storageCategory = 'userNoBackup';
  static const String songsKey = 'persistedQueue';
  static const String positionKey = 'persistedQueuePosition';

  /// A queue that auto-play keeps feeding grows without bound, and nobody
  /// scrolls back a thousand songs: past this size only a window around the
  /// playing song is stored.
  static const int maxStoredSongs = 1000;
  static const int _storedSongsBefore = 200;

  static const Duration _writeDelay = Duration(seconds: 2);
  static const Duration _positionWriteInterval = Duration(seconds: 10);

  Timer? _writeTimer;
  Map<String, dynamic>? _pendingSongs;
  String? _writtenSignature;
  DateTime _lastPositionWrite = DateTime.fromMillisecondsSinceEpoch(0);

  /// Index of the first stored song within the live queue, so a position saved
  /// on its own still points at the right entry of an already stored window.
  int _storedOffset = 0;
  int _storedLength = 0;

  int _positionIndex = 0;
  String? _positionEntryId;
  int _positionMs = 0;
  bool _positionDirty = false;

  /// Records the queue and where playback sits in it. Cheap to call on every
  /// queue change: the write is debounced and the songs are left alone when
  /// they are already the ones on disk.
  void saveQueue(List<Map> queue, List<Map> originalQueue, int index) {
    try {
      if (queue.isEmpty) {
        unawaited(clear());
        return;
      }

      final offset = _windowOffset(queue.length, index);
      final window = queue.skip(offset).take(maxStoredSongs).toList();
      final storedIndex = (index - offset).clamp(0, window.length - 1);

      _storedOffset = offset;
      _storedLength = window.length;
      _rememberPosition(
        storedIndex,
        window[storedIndex]['queueEntryId']?.toString(),
        null,
      );

      // Copies are only worth taking once the songs turn out to differ from
      // the ones on disk: this runs on every queue change, and the queue can
      // be long.
      final signature = _signatureOf(window, originalQueue.length);
      if (signature != _writtenSignature) {
        _pendingSongs = {
          'songs': cloneMaps(window),
          // The pre-shuffle order is only worth storing while shuffle is on,
          // and only whole: a window of it would restore a cut-down queue.
          'originalSongs': originalQueue.length <= maxStoredSongs
              ? cloneMaps(originalQueue)
              : const <Map<String, dynamic>>[],
          'signature': signature,
        };
      }

      _schedule();
    } catch (e, stackTrace) {
      logger.log('Error saving queue', error: e, stackTrace: stackTrace);
    }
  }

  /// Records how far into the current song playback got. Throttled, so this
  /// can be called as often as the position stream ticks.
  void savePosition(
    int index,
    String? queueEntryId,
    Duration position, {
    bool force = false,
  }) {
    try {
      final storedIndex = index - _storedOffset;
      if (storedIndex < 0 || storedIndex >= _storedLength) return;

      _rememberPosition(storedIndex, queueEntryId, position);

      final now = DateTime.now();
      if (!force &&
          now.difference(_lastPositionWrite) < _positionWriteInterval) {
        return;
      }
      _lastPositionWrite = now;
      _schedule();
    } catch (e, stackTrace) {
      logger.log(
        'Error saving queue position',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Writes whatever is still pending. Called when playback stops and when the
  /// app leaves the foreground, the last moment before the process can go.
  Future<void> flush() async {
    _writeTimer?.cancel();
    _writeTimer = null;

    final songs = _pendingSongs;
    final hadPosition = _positionDirty;
    final position = _positionRecord();
    _pendingSongs = null;
    _positionDirty = false;

    try {
      if (songs != null) {
        await addOrUpdateData(storageCategory, songsKey, songs);
        _writtenSignature = songs['signature'] as String?;
      }
      if (hadPosition) {
        await addOrUpdateData(storageCategory, positionKey, position);
      }
    } catch (e, stackTrace) {
      logger.log('Error persisting queue', error: e, stackTrace: stackTrace);
    }
  }

  /// Reads back the stored queue, or null when there is nothing usable.
  PersistedQueue? read() {
    try {
      final stored = Hive.box(storageCategory).get(songsKey);
      if (stored is! Map) return null;

      final songs = _songsOf(stored['songs']);
      if (songs.isEmpty) return null;

      _writtenSignature = stored['signature']?.toString();
      _storedOffset = 0;
      _storedLength = songs.length;

      final resumed = _readPosition(songs);
      // Seed the in-memory record so the save that follows the restore does
      // not report the resumed song as freshly started.
      _rememberPosition(
        resumed.index,
        songs[resumed.index]['queueEntryId']?.toString(),
        resumed.position,
      );
      _positionDirty = false;

      return PersistedQueue(
        queue: songs,
        originalQueue: _songsOf(stored['originalSongs']),
        index: resumed.index,
        position: resumed.position,
      );
    } catch (e, stackTrace) {
      logger.log(
        'Error reading stored queue',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> clear() async {
    _writeTimer?.cancel();
    _writeTimer = null;
    _pendingSongs = null;
    _writtenSignature = null;
    _storedOffset = 0;
    _storedLength = 0;
    _positionIndex = 0;
    _positionEntryId = null;
    _positionMs = 0;
    _positionDirty = false;

    try {
      await deleteData(storageCategory, songsKey);
      await deleteData(storageCategory, positionKey);
    } catch (e, stackTrace) {
      logger.log(
        'Error clearing stored queue',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  ({int index, Duration position}) _readPosition(
    List<Map<String, dynamic>> songs,
  ) {
    final stored = Hive.box(storageCategory).get(positionKey);
    if (stored is! Map) return (index: 0, position: Duration.zero);

    final storedIndex = stored['index'];
    final index = storedIndex is int && storedIndex >= 0 && storedIndex < songs.length
        ? storedIndex
        : 0;

    // A position only belongs to the song it was taken on: if that entry moved
    // or went away, the queue still comes back, from the start of the song.
    final milliseconds = stored['position'];
    final entryId = stored['queueEntryId']?.toString();
    if (milliseconds is! int ||
        milliseconds <= 0 ||
        entryId == null ||
        entryId != songs[index]['queueEntryId']?.toString()) {
      return (index: index, position: Duration.zero);
    }

    return (index: index, position: Duration(milliseconds: milliseconds));
  }

  void _rememberPosition(int index, String? queueEntryId, Duration? position) {
    // A different song under the same index means playback moved on, so the
    // position kept for the previous one no longer applies.
    if (queueEntryId != _positionEntryId) {
      _positionMs = 0;
    }
    if (position != null) {
      _positionMs = position.inMilliseconds;
    }
    _positionIndex = index;
    _positionEntryId = queueEntryId;
    _positionDirty = true;
  }

  Map<String, dynamic> _positionRecord() => {
    'index': _positionIndex,
    'queueEntryId': _positionEntryId,
    'position': _positionMs,
  };

  void _schedule() {
    _writeTimer ??= Timer(_writeDelay, () {
      _writeTimer = null;
      unawaited(flush());
    });
  }

  int _windowOffset(int length, int index) {
    if (length <= maxStoredSongs) return 0;
    return (index - _storedSongsBefore).clamp(0, length - maxStoredSongs);
  }

  String _signatureOf(List<Map> songs, int originalLength) {
    final buffer = StringBuffer()
      ..write(originalLength)
      ..write(':');
    for (final song in songs) {
      buffer
        ..write(song['queueEntryId'] ?? song['ytid'])
        ..write(',');
    }
    return buffer.toString();
  }

  List<Map<String, dynamic>> _songsOf(dynamic stored) {
    if (stored is! List) return <Map<String, dynamic>>[];
    return stored.whereType<Map>().map(cloneMap).toList();
  }
}
