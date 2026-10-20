import 'dart:convert';

import 'package:musify/services/local_sync/sync_data.dart';
import 'package:musify/services/local_sync/sync_merge.dart';

Map<String, dynamic> song(String id, [String? title]) => {
  'ytid': id,
  'title': title ?? id,
  'artist': 'Fixture',
};
Map<String, dynamic> playlist(
  String id,
  List<String> songs, {
  String title = 'Mix',
}) => {
  'ytid': id,
  'title': title,
  'source': 'user-created',
  'list': songs.map(song).toList(),
};
Map<String, dynamic> month(int minutes, {String id = 'a', int plays = 1}) => {
  'totalSeconds': minutes * 60,
  'songs': {
    id: {...song(id), 'seconds': minutes * 60, 'playCount': plays},
  },
};
Map<String, dynamic> recap(
  int minutes, {
  Map<String, dynamic> history = const {},
  String? currentKey,
  String id = 'a',
}) {
  final date = DateTime.now();
  return {
    'schemaVersion': 2,
    'year': date.year,
    'currentMonthKey':
        currentKey ?? '${date.year}-${date.month.toString().padLeft(2, '0')}',
    'currentMonth': month(minutes, id: id),
    'history': history,
  };
}

SyncDocument document(Map<String, dynamic> data) =>
    SyncDocument()..capture(data, null, 'initial');
SyncDocument copyDocument(SyncDocument doc) => SyncDocument.fromMap(
  Map<String, dynamic>.from(jsonDecode(canonicalSync(doc.toMap()))),
);
Map<String, dynamic> payload(
  SyncDocument doc, {
  Set<SyncCategory>? categories,
}) {
  final selected = categories ?? SyncCategory.values.toSet();
  return {
    'schemaVersion': 2,
    'categories': selected.map((e) => e.name).toList(),
    'document': doc.select(selected).toMap(),
  };
}
