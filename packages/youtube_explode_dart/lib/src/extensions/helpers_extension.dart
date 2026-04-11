import 'dart:convert';

import 'package:collection/collection.dart';

typedef JsonMap = Map<String, dynamic>;

/// Utility for Strings.
extension StringUtility on String {
  /// Returns null if this string is whitespace.
  String? get nullIfWhitespace => trim().isEmpty ? null : this;

  /// Returns null if this string is a whitespace.
  String substringUntil(String separator) => substring(0, indexOf(separator));

  ///
  String substringAfter(String separator) =>
      substring(indexOf(separator) + separator.length);

  static final _exp = RegExp(r'\D');

  /// Strips out all non digit characters.
  String stripNonDigits() => replaceAll(_exp, '');

  //void _log(String str, String filename) {
  //  Directory('requests').createSync();
  //  File('requests/$filename.json').writeAsStringSync(str);
  //}

  /// Extract and decode json from a string
  Map<String, dynamic>? extractJson([String separator = '']) {
    final index = indexOf(separator) + separator.length;
    if (index > length) {
      return null;
    }

    final str = substring(index);

    final startIdx = str.indexOf('{');
    var endIdx = str.lastIndexOf('}');

    while (true) {
      try {
        return json.decode(str.substring(startIdx, endIdx + 1))
            as Map<String, dynamic>;

        //final now = DateTime.now();
        //_log(str.substring(startIdx, endIdx + 1),
        //    '${now.minute}.${now.second}.${now.millisecond}-DECODE');
        //return value;
      } on FormatException {
        endIdx = str.lastIndexOf(str.substring(0, endIdx));
        if (endIdx == 0) {
          return null;
        }
      }
    }
  }

  /// Format: HH:MM:SS
  Duration? toDuration() {
    if (this == 'LIVE' || this == 'SHORTS' || trim().isEmpty) {
      return null;
    }

    final parts = split(':');
    assert(parts.length <= 3);

    try {
      if (parts.length == 1) {
        return Duration(seconds: int.parse(parts.first));
      }
      if (parts.length == 2) {
        return Duration(
          minutes: int.parse(parts[0]),
          seconds: int.parse(parts[1]),
        );
      }
      if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2]),
        );
      }
    } on FormatException {
      return null;
    }

    // Shouldn't reach here.
    throw StateError('Invalid duration parts');
  }

  DateTime parseDateTime() => DateTime.parse(this);

  static final _viewCountExp = RegExp(r'^(\d+\.?\d+?)([KMB])? views$');

  /// Parse view count from a string formatted as an integer and its magnitude.
  /// Example: 5 views, 1.5K views, 2.3M views, 3.4B views.
  /// If this fails returns null.
  int? parseViewCount() {
    final match = _viewCountExp.firstMatch(this);
    if (match == null) {
      return null;
    }
    if (match.groupCount != 2) {
      return null;
    }
    final count = double.tryParse(match.group(1) ?? '1');
    final unitStr = match.group(2);

    final unit = switch (unitStr) {
      'B' => 1000000000,
      'M' => 1000000,
      'K' => 1000,
      _ => 1
    };
    return (count! * unit).toInt();
  }
}

/// Utility for Strings.
extension StringUtility2 on String? {
  static final RegExp _unitSplit = RegExp(r'^(\d+(?:\.\d+)?)(\w)?');

  /// Parses this value as int stripping the non digit characters,
  /// returns null if this fails.
  int? parseInt() => int.tryParse(this?.stripNonDigits() ?? '');

  int? parseIntWithUnits() {
    if (this == null) {
      return null;
    }
    final match = _unitSplit.firstMatch(this!.trim());
    if (match == null) {
      return null;
    }
    if (match.groupCount != 2) {
      return null;
    }

    final count = double.tryParse(match.group(1) ?? '');
    if (count == null) {
      return null;
    }

    final multiplierText = match.group(2);

    var multiplier = 1;
    if (multiplierText == 'K') {
      multiplier = 1000;
    } else if (multiplierText == 'M') {
      multiplier = 1000000;
    }

    return (count * multiplier).toInt();
  }

  /// Returns true if the string is null or empty.
  bool get isNullOrWhiteSpace {
    if (this == null) {
      return true;
    }
    if (this!.trim().isEmpty) {
      return true;
    }
    return false;
  }

  /// Format: {quantity} {unit} ago (5 years ago)
  DateTime? toDateTime() {
    if (this == null) {
      return null;
    }

    var parts = this!.trim().split(' ');
    if (parts.length == 4) {
      // Streamed x y ago
      parts = parts.skip(1).toList();
    }

    if (parts.length != 3) {
      return null;
    }

    final qty = int.parse(parts.first);

    // Try to get the unit
    final unit = parts[1];

    final time = switch (unit) {
      _ when unit.startsWith('second') => Duration(seconds: qty),
      _ when unit.startsWith('minute') => Duration(minutes: qty),
      _ when unit.startsWith('hour') => Duration(hours: qty),
      _ when unit.startsWith('day') => Duration(days: qty),
      _ when unit.startsWith('week') => Duration(days: qty * 7),
      _ when unit.startsWith('month') => Duration(days: qty * 30),
      _ when unit.startsWith('year') => Duration(days: qty * 365),
      _ => throw StateError("Couldn't parse $unit unit of time. "
          'Please report this to the project page!')
    };

    return DateTime.now().subtract(time);
  }

  Uri? toUri() {
    if (this == null) {
      return null;
    }
    try {
      return Uri.parse(this!);
    } on FormatException {
      return null;
    }
  }

  DateTime? tryParseDateTime() {
    if (this == null) {
      return null;
    }
    return DateTime.parse(this!);
  }
}

/// List Utility.
extension ListUtil<E> on Iterable<E> {
  /// Same as [elementAt] but if the index is higher than the length returns
  /// null
  E? elementAtSafe(int index) {
    if (index >= length) {
      return null;
    }
    return elementAt(index);
  }
}

/// Uri utility
extension UriUtility on Uri {
  /// Returns a new Uri with the new query parameters set.
  Uri setQueryParam(String key, String value) {
    final query = Map<String, String>.from(queryParameters);

    query[key] = value;

    return replace(queryParameters: query);
  }
}

///
extension GetOrNullMap on Map {
  /// Get a map inside a map
  Map<String, dynamic>? get(String key, [String? orKey]) {
    final v = this[key] ?? (orKey == null ? null : this[orKey]);
    if (v == null) {
      return null;
    }
    return v;
  }

  /// Get a value inside a map.
  /// If it is null this returns null, or another type this throws.
  T? getT<T extends Object>(String key) {
    final v = this[key];
    if (v == null) {
      return null;
    }
    if (v is! T) {
      throw Exception('Invalid type: ${v.runtimeType} should be $T');
    }
    return v;
  }

  /// Get a [List<Map<String, dynamic>>>] from a map.
  List<Map<String, dynamic>>? getList(String key, [String? orKey]) {
    var v = this[key];
    if (v == null) {
      if (orKey != null) {
        v = this[orKey];
        if (v == null) {
          return null;
        }
      } else {
        return null;
      }
    }
    if (v is! List<dynamic>) {
      throw Exception('Invalid type: ${v.runtimeType} should be of type List');
    }

    return v.toList().cast<Map<String, dynamic>>();
  }

  /// Access a value by using the json selection, for example contents/column/1/id
  T? getJson<T>(String jsonPath) {
    final parts = jsonPath.split('/');
    dynamic value = this;
    for (final part in parts) {
      if (value is Map<String, dynamic>) {
        value = value[part];
      } else if (value is List<dynamic>) {
        final index = int.tryParse(part);
        if (index == null) {
          return null;
        }
        if (index >= value.length) {
          return null;
        }
        value = value[index];
      } else {
        return null;
      }
    }
    return value as T;
  }
}

///
extension UriUtils on Uri {
  ///
  Uri replaceQueryParameters(Map<String, String> parameters) {
    final query = Map<String, String>.from(queryParameters);
    query.addAll(parameters);

    return replace(queryParameters: query);
  }
}

/// Parse properties with `text` method.
extension RunsParser on List<Map<dynamic, dynamic>> {
  ///
  String parseRuns() => map((e) => e['text']).join();
}

extension GenericExtract on List<String> {
  /// Used to extract initial data.
  T extractGenericData<T>(
    List<String> match,
    T Function(Map<String, dynamic>) builder,
    Exception Function() orThrow,
  ) {
    JsonMap? initialData;

    for (final m in match) {
      initialData = firstWhereOrNull((e) => e.contains(m))?.extractJson(m);
      if (initialData != null) {
        return builder(initialData);
      }
    }

    throw orThrow();
  }
}
