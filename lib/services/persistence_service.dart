import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/main.dart';

class PersistenceService {
  factory PersistenceService() => _instance;
  PersistenceService._internal();
  static final PersistenceService _instance = PersistenceService._internal();

  final Map<String, Map<String, Timer>> _debounceTimers = {};
  final Map<String, Map<String, dynamic>> _pendingChanges = {};

  // Default debounce delay
  final Duration _defaultDelay = const Duration(seconds: 2);

  // Save data with debouncing
  void saveData(String boxName, String key, dynamic value, {Duration? delay}) {
    // Initialize maps if they don't exist for this box
    _debounceTimers[boxName] ??= {};
    _pendingChanges[boxName] ??= {};

    // Store the value to be saved
    _pendingChanges[boxName]![key] = value;

    // Cancel existing timer if there is one
    _debounceTimers[boxName]![key]?.cancel();

    // Create a new timer
    _debounceTimers[boxName]![key] = Timer(delay ?? _defaultDelay, () {
      _saveToHive(boxName, key, _pendingChanges[boxName]![key]);
      _debounceTimers[boxName]!.remove(key);
      _pendingChanges[boxName]!.remove(key);
    });
  }

  // Force immediate save
  void forceSave(String boxName, String key) {
    if (_pendingChanges.containsKey(boxName) &&
        _pendingChanges[boxName]!.containsKey(key)) {
      _debounceTimers[boxName]?[key]?.cancel();
      _saveToHive(boxName, key, _pendingChanges[boxName]![key]);
      _debounceTimers[boxName]!.remove(key);
      _pendingChanges[boxName]!.remove(key);
    }
  }

  // Force save all pending changes
  void forceSaveAll() {
    for (final boxName in _pendingChanges.keys) {
      for (final key in _pendingChanges[boxName]!.keys) {
        _debounceTimers[boxName]?[key]?.cancel();
        _saveToHive(boxName, key, _pendingChanges[boxName]![key]);
      }
    }
    _debounceTimers.clear();
    _pendingChanges.clear();
  }

  // Private method to actually save to Hive
  void _saveToHive(String boxName, String key, dynamic value) {
    try {
      final box = Hive.box(boxName);
      box.put(key, value);
    } catch (e, stackTrace) {
      logger.log('Error saving data to Hive:', e, stackTrace);
    }
  }
}
