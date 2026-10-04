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

int indexAfterQueueReorder(int index, int oldIndex, int newIndex) {
  if (index == oldIndex) return newIndex;
  if (oldIndex < index && newIndex >= index) return index - 1;
  if (oldIndex > index && newIndex <= index) return index + 1;
  return index;
}

int? appendedQueueIndexForSourceIndex(
  List<Map> songs,
  int sourceIndex,
  int existingQueueLength,
) {
  if (sourceIndex < 0 || sourceIndex >= songs.length) return null;

  var appendedSongCount = 0;
  for (var index = 0; index <= sourceIndex; index++) {
    final song = songs[index];
    final ytid = song['ytid']?.toString();
    if (ytid == null || ytid.isEmpty) continue;
    if (index == sourceIndex) return existingQueueLength + appendedSongCount;
    appendedSongCount++;
  }

  return null;
}

({List<Map> songs, int currentIndex}) shuffleQueueOrder({
  required Iterable<Map> songs,
  required Map currentSong,
  required List<Map> unplayedManualSongs,
  required Set<String> manualSongIds,
  required QueueEntryIdManager queueEntryIds,
}) {
  final currentQueueEntryId = queueEntryIds.ensureId(currentSong);
  final shuffledSongs = <Map>[];

  for (final song in songs) {
    final queueEntryId = queueEntryIds.ensureId(song);
    if (queueEntryId != currentQueueEntryId &&
        !manualSongIds.contains(queueEntryId)) {
      shuffledSongs.add(song);
    }
  }

  shuffledSongs.shuffle();
  return (
    songs: [currentSong, ...unplayedManualSongs, ...shuffledSongs],
    currentIndex: 0,
  );
}

({List<Map> songs, int currentIndex}) restoreQueueOrder({
  required Iterable<Map> originalSongs,
  required Map currentSong,
  required List<Map> unplayedManualSongs,
  required Set<String> manualSongIds,
  required QueueEntryIdManager queueEntryIds,
}) {
  final currentQueueEntryId = queueEntryIds.ensureId(currentSong);
  final restoredSongs = <Map>[];
  var currentIndex = -1;

  for (final song in originalSongs) {
    final queueEntryId = queueEntryIds.ensureId(song);
    if (manualSongIds.contains(queueEntryId)) continue;
    if (queueEntryId == currentQueueEntryId) {
      currentIndex = restoredSongs.length;
    }
    restoredSongs.add(song);
  }

  if (currentIndex == -1) {
    restoredSongs.insert(0, currentSong);
    currentIndex = 0;
  }
  restoredSongs.insertAll(currentIndex + 1, unplayedManualSongs);

  return (songs: restoredSongs, currentIndex: currentIndex);
}

class QueueEntryIdManager {
  int _counter = 0;

  String nextId() {
    return 'queue-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';
  }

  String ensureId(Map song) {
    final existingId = song['queueEntryId']?.toString();
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final generatedId = nextId();
    song['queueEntryId'] = generatedId;
    return generatedId;
  }

  Map<String, dynamic> createSong(Map song) {
    final queueSong = Map<String, dynamic>.from(song);
    queueSong['queueEntryId'] = nextId();
    return queueSong;
  }

  void ensureIds(Iterable<Map> songs) {
    for (final song in songs) {
      ensureId(song);
    }
  }
}
