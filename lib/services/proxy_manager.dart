/*
 *     Copyright (C) 2025 Valeri Gokadze
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
    // initialize default youtube client and subscribe to proxy toggle
    _defaultYt = YoutubeExplode();
    _sharedYt = _defaultYt;
    // If proxy is already enabled at startup, initialize the shared proxy-backed client.
    if (useProxy.value) {
      // Fire-and-forget initialization; listener will also handle future toggles.
      _initSharedProxyClient();
    }
    // react to proxy setting changes
    useProxy.addListener(() async {
        if (useProxy.value) {
        await _initSharedProxyClient();
      } else {
        // switch back to default client
        if (_sharedYt != _defaultYt) {
          try {
            _sharedYt?.close();
          } catch (_) {}
          _sharedYt = _defaultYt;
        }
      }
    });
  }

  static final ProxyManager _instance = ProxyManager._internal();

  /// Default non-proxy YoutubeExplode instance (long-lived)
  late final YoutubeExplode _defaultYt;

  /// Currently active shared YoutubeExplode - either [_defaultYt] or a
  /// proxy-backed client. Use [getClientSync] to access.
  YoutubeExplode? _sharedYt;

  bool _initializingSharedClient = false;

  Future<void>? _fetchingProxiesFuture;
  bool _hasFetched = false;
  final Map<String, List<ProxyInfo>> _proxiesByCountry = {};
  final Set<ProxyInfo> _workingProxies = {};
  final _random = Random();
  DateTime _lastFetched = DateTime.now();

  Future<void> _fetchProxies() async {
    if (!useProxy.value) return;
    try {
      final fetchTasks =
          <Future>[]
            ..add(_fetchSpysMe())
            ..add(_fetchProxyScrape())
            ..add(_fetchOpenProxyList());
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
    if (_initializingSharedClient) return;
    _initializingSharedClient = true;
    try {
      // Ensure proxies available
      if (!_hasFetched) await _fetchProxies();
      if (_proxiesByCountry.isEmpty) await _fetchProxies();

      // Try to acquire a working proxy and create a client
      do {
        final proxy = await _getRandomProxy();
        if (proxy == null) break;
        HttpClient? httpClient;
        IOClient? ioClient;
        try {
          httpClient =
              HttpClient()
                ..connectionTimeout = Duration(seconds: timeoutSeconds)
                ..findProxy = (_) {
                  return 'PROXY ${proxy.address}; DIRECT';
                }
                ..badCertificateCallback = (context, _context, ___) {
                  return false;
                };

          ioClient = IOClient(httpClient);
          final ytClient = YoutubeExplode(YoutubeHttpClient(ioClient));

          // Set as shared client
          // Close previous shared proxy-backed client if any (but keep default)
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
    } finally {
      _initializingSharedClient = false;
    }
  }

  /// Returns the currently active YoutubeExplode client. Never null.
  YoutubeExplode getClientSync() => _sharedYt ?? _defaultYt;

  Future<StreamManifest?> _validateDirect(
    String songId,
    int timeoutSeconds,
  ) async {
    try {
      final manifest = await YoutubeExplode().videos.streams
          .getManifest(songId)
          .timeout(Duration(seconds: timeoutSeconds));
      return manifest;
    } catch (e) {
      return null;
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
    try {
      httpClient =
          HttpClient()
            ..connectionTimeout = Duration(seconds: timeoutSeconds)
            ..findProxy = (_) {
              return 'PROXY ${proxy.address}; DIRECT';
            }
            ..badCertificateCallback = (context, _context, ___) {
              return false;
            };
      ioClient = IOClient(httpClient);
      final ytClient = YoutubeExplode(YoutubeHttpClient(ioClient));
      final manifest = await ytClient.videos.streams
          .getManifest(songId)
          .timeout(Duration(seconds: timeoutSeconds));
      _workingProxies.add(proxy);
      return manifest;
    } catch (e) {
      httpClient?.close(force: true);
      ioClient?.close();
      return null;
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
        final idx =
            _workingProxies.length == 1
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
        final countryProxies =
            _proxiesByCountry[countryCode] ??
            _proxiesByCountry.values.expand((x) => x).toList();
        if (countryProxies.isEmpty) {
          return null;
        }
        if (countryProxies.length == 1) {
          proxy = countryProxies.removeLast();
        } else {
          proxy = countryProxies.removeAt(
            _random.nextInt(countryProxies.length),
          );
        }
      }
      return proxy;
    } catch (e) {
      return null;
    }
  }

  Future<StreamManifest?> getSongManifest(String songId) async {
    if (!useProxy.value) {
      return _validateDirect(songId, 5);
    }
    var manifest = await _validateDirect(songId, 5);
    if (manifest != null) return manifest;
    if (DateTime.now().difference(_lastFetched).inMinutes >= 60)
      await _fetchProxies();
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
  /// Caller is responsible for calling `close()` on the returned
  /// [YoutubeExplode] when finished to free resources.
  Future<YoutubeExplode?> getYoutubeExplodeClient({
    int timeoutSeconds = 5,
  }) async {
    if (!useProxy.value) return null;
    // Ensure proxies have been fetched
    if (!_hasFetched) await _fetchProxies();

    // If there are no proxies available, try fetching once more
    if (_proxiesByCountry.isEmpty) await _fetchProxies();

    if (_proxiesByCountry.isEmpty) return null;

    // Try proxies until we can construct a client that can perform a simple
    // request (we won't perform a heavy request here, the caller will use
    // the returned client for operations like search).
    do {
      final proxy = await _getRandomProxy();
      if (proxy == null) break;

      HttpClient? httpClient;
      IOClient? ioClient;
      try {
        httpClient =
            HttpClient()
              ..connectionTimeout = Duration(seconds: timeoutSeconds)
              ..findProxy = (_) {
                return 'PROXY ${proxy.address}; DIRECT';
              }
              ..badCertificateCallback = (context, _context, ___) {
                return false;
              };

        ioClient = IOClient(httpClient);
        final ytClient = YoutubeExplode(YoutubeHttpClient(ioClient));

        // Don't run a test request here to keep it lightweight. Assume proxy
        // is usable; if caller experiences errors they can close and retry.
        _workingProxies.add(proxy);
        return ytClient;
      } catch (e) {
        // Clean up on failure and try another proxy
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
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      response.body.split('\n').forEach((line) {
        final rgx = RegExp(
          r'(?<ip>\d+\.\d+\.\d+\.\d+):(?<port>\d+)\s(?<country>[A-Z]{2})-(?<anon>[HNA!]{1,2})(?:\s|-)(?<ssl>[\sS!]*)',
        );
        final match = rgx.firstMatch(line);
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
      logger.log(
        'ProxyManager: Error fetching proxies from spys.me: $e',
        null,
        null,
      );
    }
  }

  Future<void> _fetchProxyScrape() async {
    if (!useProxy.value) return;
    try {
      const url =
          'https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&proxy_format=protocolipport&format=json';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      final result = jsonDecode(response.body);
      for (final proxyData in (result['proxies'] as List)) {
        if (proxyData['ip_data'] != null &&
            (proxyData['alive'] ?? false) &&
            proxyData['ip_data']['countryCode'] != null &&
            (proxyData['ssl'] ?? false)) {
          final country = proxyData['ip_data']['countryCode'];
          _proxiesByCountry[country] = _proxiesByCountry[country] ?? [];
          _proxiesByCountry[country]!.add(
            ProxyInfo(
              source: 'proxyscrape.com',
              address: '${proxyData['ip']}:${proxyData['port']}',
              country: country,
              isSsl: proxyData['ssl'],
            ),
          );
        }
      }
    } catch (e) {
      logger.log(
        'ProxyManager: Error fetching proxies from proxyscrape.com: $e',
        null,
        null,
      );
    }
  }

  Future<void> _fetchOpenProxyList() async {
    if (!useProxy.value) return;
    try {
      const url =
          'https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS.txt';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return;
      response.body.split('\n').forEach((line) {
        final rgx = RegExp(
          r'(.)\s(?<ip>\d+\.\d+\.\d+\.\d+):(?<port>\d+)\s(?:(?<responsetime>\d+)(?:ms))\s(?<country>[A-Z]{2})\s(?<isp>.+)$',
        );
        final match = rgx.firstMatch(line);
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
      logger.log(
        'ProxyManager: Error fetching proxies from openproxylist: $e',
        null,
        null,
      );
    }
  }
}
