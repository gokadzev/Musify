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
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:musify/main.dart';
import 'package:musify/models/proxy_model.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ProxyManager {
  // Singleton
  factory ProxyManager() => _instance;
  ProxyManager._internal() {
    _defaultYt = YoutubeExplode();
    _sharedYt = _defaultYt;
    if (useProxy.value) {
      _initSharedProxyClient();
    }
    useProxy.addListener(() async {
      if (useProxy.value) {
        await _initSharedProxyClient();
      } else {
        if (_sharedYt != _defaultYt) {
          try {
            _sharedYt?.close();
          } catch (_) {}
          _sharedYt = _defaultYt;
        }
      }
    });
  }
  // Timeout constants
  static const int _validateDirectTimeout = 5;
  static const int _proxyRefreshIntervalMinutes = 60;

  // Regex patterns (compiled once)
  static final RegExp _spysRegex = RegExp(
    r'(?<ip>\d+\.\d+\.\d+\.\d+):(?<port>\d+)\s(?<country>[A-Z]{2})-(?<anon>[HNA!]{1,2})(?:\s|-)(?<ssl>[\sS!]*)',
  );
  static final RegExp _openProxyRegex = RegExp(
    r'(.)\s(?<ip>\d+\.\d+\.\d+\.\d+):(?<port>\d+)\s(?:(?<responsetime>\d+)(?:ms))\s(?<country>[A-Z]{2})\s(?<isp>.+)$',
  );

  static final ProxyManager _instance = ProxyManager._internal();

  /// Default non-proxy YoutubeExplode instance (long-lived)
  late final YoutubeExplode _defaultYt;

  /// Currently active shared YoutubeExplode - either [_defaultYt] or a
  /// proxy-backed client. Use [getClientSync] to access.
  YoutubeExplode? _sharedYt;

  Future<void>? _fetchingProxiesFuture;
  Completer<void>? _initializationCompletion;
  bool _hasFetched = false;
  final Map<String, List<ProxyInfo>> _proxiesByCountry = {};
  final Set<ProxyInfo> _workingProxies = {};
  final _random = Random();
  DateTime _lastFetched = DateTime.now();
  DateTime _lastProxyCleanup = DateTime.now();
  static const int _proxyCleanupIntervalMinutes = 120;

  Future<void> _fetchProxies() async {
    if (!useProxy.value) return;
    try {
      // Clear existing candidates to avoid duplicates and stale proxies
      _proxiesByCountry.clear();

      final fetchTasks = <Future>[]
        ..add(_fetchProxyScrape())
        ..add(_fetchGeonode())
        ..add(_fetchOpenProxyList())
        ..add(_fetchSpysMe());
      _fetchingProxiesFuture = Future.wait(fetchTasks);
      await _fetchingProxiesFuture?.whenComplete(() {
        _hasFetched = true;
        _lastFetched = DateTime.now();
      });
    } catch (e) {
      logger.log('ProxyManager: Error fetching proxies: $e', null, null);
    }
  }

  /// Initialize a shared YoutubeExplode client that uses a working proxy.
  Future<void> _initSharedProxyClient({int timeoutSeconds = 5}) async {
    if (_initializationCompletion != null) {
      return _initializationCompletion!.future;
    }

    _initializationCompletion = Completer<void>();
    try {
      if (!_hasFetched) await _fetchProxies();
      if (_proxiesByCountry.isEmpty) await _fetchProxies();

      do {
        final proxy = await _getRandomProxy();
        if (proxy == null) break;
        HttpClient? httpClient;
        IOClient? ioClient;
        try {
          httpClient = HttpClient()
            ..connectionTimeout = Duration(seconds: timeoutSeconds)
            ..findProxy = (_) {
              return 'PROXY ${proxy.address}; DIRECT';
            }
            ..badCertificateCallback = (context, _context, ___) {
              return true;
            };

          ioClient = IOClient(httpClient);
          final ytClient = YoutubeExplode(
            httpClient: YoutubeHttpClient(ioClient),
          );

          if (_sharedYt != null && _sharedYt != _defaultYt) {
            try {
              _sharedYt?.close();
            } catch (_) {}
          }
          _sharedYt = ytClient;
          _workingProxies.add(proxy);
          break;
        } catch (e) {
          try {
            ioClient?.close();
          } catch (_) {}
          try {
            httpClient?.close(force: true);
          } catch (_) {}
          continue;
        }
      } while (true);
    } catch (e, stackTrace) {
      logger.log('Error initializing proxy client', e, stackTrace);
    } finally {
      _initializationCompletion?.complete();
      _initializationCompletion = null;
    }
  }

  /// Returns the currently active YoutubeExplode client. Never null.
  YoutubeExplode getClientSync() => _sharedYt ?? _defaultYt;

  Future<StreamManifest?> _validateDirect(
    String songId,
    int timeoutSeconds,
  ) async {
    final ytClient = YoutubeExplode();
    try {
      final manifest = await ytClient.videos.streams
          .getManifest(songId, ytClients: [YoutubeApiClient.androidVr])
          .timeout(Duration(seconds: timeoutSeconds));
      return manifest;
    } catch (e) {
      return null;
    } finally {
      try {
        ytClient.close();
      } catch (_) {}
    }
  }

  Future<StreamManifest?> _validateProxy(
    ProxyInfo proxy,
    String songId,
    int timeoutSeconds,
  ) async {
    if (!useProxy.value) return null;
    IOClient? ioClient;
    HttpClient? httpClient;
    YoutubeExplode? ytClient;
    try {
      httpClient = HttpClient()
        ..connectionTimeout = Duration(seconds: timeoutSeconds)
        ..findProxy = (_) {
          return 'PROXY ${proxy.address}; DIRECT';
        }
        ..badCertificateCallback = (context, _context, ___) {
          return true;
        };
      ioClient = IOClient(httpClient);
      ytClient = YoutubeExplode(httpClient: YoutubeHttpClient(ioClient));
      final manifest = await ytClient.videos.streams
          .getManifest(songId, ytClients: [YoutubeApiClient.androidVr])
          .timeout(Duration(seconds: timeoutSeconds));
      _workingProxies.add(proxy);
      return manifest;
    } catch (e) {
      return null;
    } finally {
      try {
        ytClient?.close();
      } catch (_) {}
      try {
        ioClient?.close();
      } catch (_) {}
      try {
        httpClient?.close(force: true);
      } catch (_) {}
    }
  }

  /// Periodically clean up old proxies to prevent memory bloat
  void _maybeCleanupProxies() {
    if (DateTime.now().difference(_lastProxyCleanup).inMinutes <
        _proxyCleanupIntervalMinutes) {
      return;
    }

    _lastProxyCleanup = DateTime.now();

    if (DateTime.now().difference(_lastFetched).inMinutes >= 120) {
      _proxiesByCountry.clear();
      _workingProxies.clear();
      _hasFetched = false;
    }
  }

  Future<ProxyInfo?> _getRandomProxy({String? preferredCountry}) async {
    if (!useProxy.value) return null;
    try {
      if (!_hasFetched) await _fetchingProxiesFuture;
      if (_hasFetched && _proxiesByCountry.isEmpty) await _fetchProxies();
      if (_proxiesByCountry.isEmpty) return null;
      ProxyInfo proxy;
      String countryCode;
      if (_workingProxies.isNotEmpty) {
        final idx = _workingProxies.length == 1
            ? 0
            : _random.nextInt(_workingProxies.length);
        proxy = _workingProxies.elementAt(idx);
        _workingProxies.remove(proxy);
      } else {
        if (preferredCountry != null &&
            _proxiesByCountry.containsKey(preferredCountry)) {
          countryCode = preferredCountry;
        } else {
          countryCode = _proxiesByCountry.keys.first;
        }
        final countryProxies = _proxiesByCountry[countryCode];
        if (countryProxies == null || countryProxies.isEmpty) {
          if (_proxiesByCountry.isEmpty) return null;
          final allProxies = _proxiesByCountry.values.expand((x) => x).toList();
          if (allProxies.isEmpty) return null;
          proxy = allProxies[_random.nextInt(allProxies.length)];
        } else {
          proxy = countryProxies[_random.nextInt(countryProxies.length)];
        }
      }
      return proxy;
    } catch (e) {
      return null;
    }
  }

  Future<StreamManifest?> getSongManifest(String songId) async {
    if (!useProxy.value) {
      return _validateDirect(songId, _validateDirectTimeout);
    }
    var manifest = await _validateDirect(songId, _validateDirectTimeout);
    if (manifest != null) return manifest;

    if (DateTime.now().difference(_lastFetched).inMinutes >=
        _proxyRefreshIntervalMinutes) {
      await _fetchProxies();
    }

    _maybeCleanupProxies();

    manifest = await _tryProxies(songId);
    return manifest;
  }

  Future<StreamManifest?> _tryProxies(String songId) async {
    if (!useProxy.value) return null;
    StreamManifest? manifest;
    do {
      final proxy = await _getRandomProxy();
      if (proxy == null) break;
      manifest = await _validateProxy(proxy, songId, 5);
    } while (manifest == null);
    return manifest;
  }

  /// Try to create a [YoutubeExplode] client that routes requests through a
  /// working proxy. Returns null if no proxy client could be created.
  ///
  /// **IMPORTANT**: Caller is responsible for calling `close()` on the returned
  /// [YoutubeExplode] when finished to free resources. Failure to close will leak
  /// HTTP connections and memory.
  Future<YoutubeExplode?> getYoutubeExplodeClient({
    int timeoutSeconds = 5,
  }) async {
    if (!useProxy.value) return null;
    if (!_hasFetched) await _fetchProxies();

    if (_proxiesByCountry.isEmpty) await _fetchProxies();

    if (_proxiesByCountry.isEmpty) return null;

    do {
      final proxy = await _getRandomProxy();
      if (proxy == null) break;

      HttpClient? httpClient;
      IOClient? ioClient;
      try {
        httpClient = HttpClient()
          ..connectionTimeout = Duration(seconds: timeoutSeconds)
          ..findProxy = (_) {
            return 'PROXY ${proxy.address}; DIRECT';
          }
          ..badCertificateCallback = (context, _context, ___) {
            return true;
          };

        ioClient = IOClient(httpClient);
        final ytClient = YoutubeExplode(
          httpClient: YoutubeHttpClient(ioClient),
        );

        _workingProxies.add(proxy);
        return ytClient;
      } catch (e) {
        try {
          ioClient?.close();
        } catch (_) {}
        try {
          httpClient?.close(force: true);
        } catch (_) {}
        continue;
      }
    } while (true);

    return null;
  }

  Future<void> _fetchSpysMe() async {
    if (!useProxy.value) return;
    try {
      const url = 'https://spys.me/proxy.txt';
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('', 408),
          );

      if (response.statusCode != 200) {
        _logProxyFetchError('spys.me', 'Status code: ${response.statusCode}');
        return;
      }

      if (response.body.isEmpty) return;

      response.body.split('\n').forEach((line) {
        if (line.trim().isEmpty || line.startsWith(';'))
          return; // Skip comments/empty lines

        // Use pre-compiled regex (constant)
        final match = _spysRegex.firstMatch(line);
        if (match != null) {
          final country = match.namedGroup('country') ?? '';
          if (country.isNotEmpty) {
            _proxiesByCountry[country] = _proxiesByCountry[country] ?? [];
            _proxiesByCountry[country]!.add(
              ProxyInfo(
                source: 'spys.me',
                address:
                    '${match.namedGroup('ip')}:${match.namedGroup('port')}',
                country: country,
                isSsl: (match.namedGroup('ssl') ?? '').trim().isNotEmpty,
              ),
            );
          }
        }
      });
    } catch (e) {
      _logProxyFetchError('spys.me', e);
    }
  }

  void _logProxyFetchError(String source, dynamic error) {
    logger.log(
      'ProxyManager: Error fetching proxies from $source: $error',
      error,
      null,
    );
  }

  Future<void> _fetchProxyScrape() async {
    if (!useProxy.value) return;
    try {
      const url =
          'https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=json&protocol=http&ssl=yes';
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('', 408),
          );
      if (response.statusCode != 200) return;

      Map<String, dynamic> result;
      try {
        result = jsonDecode(response.body);
      } catch (_) {
        return; // Invalid JSON
      }

      if (result['proxies'] is! List) return;

      for (final proxyData in (result['proxies'] as List)) {
        if (proxyData is! Map) continue;

        if (proxyData['ip_data'] != null &&
            (proxyData['alive'] ?? false) &&
            proxyData['ip_data']['countryCode'] != null) {
          final country = proxyData['ip_data']['countryCode'];
          _proxiesByCountry[country] = _proxiesByCountry[country] ?? [];
          _proxiesByCountry[country]!.add(
            ProxyInfo(
              source: 'proxyscrape.com',
              address: '${proxyData['ip']}:${proxyData['port']}',
              country: country,
              isSsl: true,
            ),
          );
        }
      }
    } catch (e) {
      _logProxyFetchError('proxyscrape.com', e);
    }
  }

  Future<void> _fetchOpenProxyList() async {
    if (!useProxy.value) return;
    try {
      const url =
          'https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS.txt';
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('', 408),
          );
      if (response.statusCode != 200) return;
      response.body.split('\n').forEach((line) {
        // Use pre-compiled regex (constant)
        final match = _openProxyRegex.firstMatch(line);
        if (match != null) {
          final country = match.namedGroup('country') ?? '';
          if (country.isNotEmpty) {
            _proxiesByCountry[country] = _proxiesByCountry[country] ?? [];
            _proxiesByCountry[country]!.add(
              ProxyInfo(
                source: 'openproxylist',
                address:
                    '${match.namedGroup('ip')}:${match.namedGroup('port')}',
                country: country,
                isSsl: true,
              ),
            );
          }
        }
      });
    } catch (e) {
      _logProxyFetchError('openproxylist', e);
    }
  }

  Future<void> _fetchGeonode() async {
    if (!useProxy.value) return;
    try {
      const url =
          'https://proxylist.geonode.com/api/proxy-list?limit=50&page=1&sort_by=lastChecked&sort_type=desc&protocols=http%2Chttps';
      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => http.Response('', 408),
          );
      if (response.statusCode != 200) return;

      final result = jsonDecode(response.body);
      final data = result['data'];
      if (data is! List) return;

      for (final item in data) {
        if (item is! Map) continue;
        final ip = item['ip'];
        final port = item['port'];
        final country = item['country'];

        if (ip != null && port != null && country != null) {
          _proxiesByCountry[country] = _proxiesByCountry[country] ?? [];
          _proxiesByCountry[country]!.add(
            ProxyInfo(
              source: 'geonode',
              address: '$ip:$port',
              country: country,
              isSsl: true,
            ),
          );
        }
      }
    } catch (e) {
      _logProxyFetchError('geonode', e);
    }
  }
}
