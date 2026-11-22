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

import 'package:flutter/foundation.dart';

/// Holds the songs ticked in a list while it is in selection mode.
///
/// Selection mode is local to one screen: a long press enters it, leaving it
/// drops everything that was ticked.
///
/// Ticks are kept in the order they were made, not in the order the list
/// reads. Ticking 3, then 2, 6 and 1 and asking for "add to queue" queues
/// 3, 2, 6, 1: the batch actions replay [selectedSongs] as it stands.
class SongSelectionController extends ChangeNotifier {
  final List<Map> _selectedSongs = [];
  bool _isActive = false;

  /// Whether the list is showing checkboxes instead of playing on tap.
  bool get isActive => _isActive;

  int get selectedCount => _selectedSongs.length;

  bool get hasSelection => _selectedSongs.isNotEmpty;

  /// The ticked songs, first ticked first.
  List<Map> get selectedSongs => List<Map>.unmodifiable(_selectedSongs);

  bool isSelected(Map song) => _indexOf(song) != -1;

  /// Enters selection mode on [song], the one that was long pressed.
  void start(Map song) {
    if (_isActive) {
      toggle(song);
      return;
    }
    _isActive = true;
    _selectedSongs
      ..clear()
      ..add(song);
    notifyListeners();
  }

  /// Ticks [song], or unticks it when it was already ticked.
  void toggle(Map song) {
    final index = _indexOf(song);
    if (index == -1) {
      _selectedSongs.add(song);
    } else {
      _selectedSongs.removeAt(index);
    }
    notifyListeners();
  }

  /// Ticks every song of [songs] that is not ticked yet, in list order.
  void selectAll(Iterable<Map> songs) {
    var changed = false;
    for (final song in songs) {
      if (_indexOf(song) == -1) {
        _selectedSongs.add(song);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  /// Leaves selection mode and forgets what was ticked.
  void exit() {
    if (!_isActive && _selectedSongs.isEmpty) return;
    _isActive = false;
    _selectedSongs.clear();
    notifyListeners();
  }

  int _indexOf(Map song) {
    final key = _keyOf(song);
    return _selectedSongs.indexWhere((selected) => _keyOf(selected) == key);
  }

  /// Songs travel as copies between the lists and the queue, so they are
  /// matched on their id rather than on the map itself.
  String _keyOf(Map song) {
    final ytid = song['ytid']?.toString() ?? '';
    return ytid.isNotEmpty ? ytid : identityHashCode(song).toString();
  }
}
