import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/services/common_services.dart';
import 'package:musify/services/playlists_manager.dart';
import 'package:musify/utilities/flutter_toast.dart';
import 'package:musify/utilities/url_launcher.dart';
import 'package:musify/widgets/mini_player.dart';

class ImportSpotifyPlaylistPage extends StatefulWidget {
  const ImportSpotifyPlaylistPage({super.key});

  @override
  State<ImportSpotifyPlaylistPage> createState() =>
      _ImportSpotifyPlaylistPageState();
}

class _ImportSpotifyPlaylistPageState extends State<ImportSpotifyPlaylistPage> {
  final _csvController = TextEditingController();
  final _playlistNameController = TextEditingController();
  bool _isImporting = false;
  String? _fileName;

  @override
  void dispose() {
    _csvController.dispose();
    _playlistNameController.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result.isEmpty || !mounted) return;

    final file = result.single;
    final path = file.path;
    if (path == null) return;
    _csvController.text = await File(path).readAsString();
    if (!mounted) return;
    setState(() => _fileName = file.name);
  }

  Future<void> _importPlaylist() async {
    if (_isImporting) return;
    final playlistName = _playlistNameController.text.trim();
    if (playlistName.isEmpty) {
      showToast(context, context.l10n!.enterPlaylistName);
      return;
    }
    final records = _parseCsv(_csvController.text);
    if (records.length < 2) {
      showToast(context, context.l10n!.spotifyPlaylistEmpty);
      return;
    }

    final headers = records.first
        .map((header) => header.replaceFirst('\ufeff', '').trim().toLowerCase())
        .toList();
    final songIndex = headers.indexOf('song');
    final artistIndex = headers.indexOf('artist');
    if (songIndex == -1 || artistIndex == -1) {
      showToast(context, context.l10n!.spotifyPlaylistInvalid);
      return;
    }

    final songs = records.skip(1).where((row) {
      return row.length > songIndex &&
          row.length > artistIndex &&
          row[songIndex].trim().isNotEmpty;
    }).toList();
    if (songs.isEmpty) {
      showToast(context, context.l10n!.spotifyPlaylistEmpty);
      return;
    }

    setState(() => _isImporting = true);
    final foundSongs = <Map>[];
    final missingSongs = <String>[];
    for (final row in songs) {
      final title = row[songIndex].trim();
      final artist = row.length > artistIndex ? row[artistIndex].trim() : '';
      final results = await fetchSongsList('$title $artist');
      if (results.isEmpty) {
        missingSongs.add('$title - $artist');
      } else {
        foundSongs.add(Map<String, dynamic>.from(results.first));
      }
    }

    if (!mounted) return;
    final (_, playlistId) = createCustomPlaylist(playlistName, null, context);
    addSongsInCustomPlaylist(context, playlistId, foundSongs);
    setState(() => _isImporting = false);

    final resultText = context.l10n!.spotifyPlaylistImportResult(
      foundSongs.length,
      songs.length,
    );
    if (missingSongs.isNotEmpty) {
      final missingText = missingSongs.join('\n');
      await Clipboard.setData(ClipboardData(text: missingText));
      if (mounted) {
        showToastWithButton(
          context,
          '$resultText\n${context.l10n!.spotifyPlaylistMissingSongs}',
          context.l10n!.copy,
          () => Clipboard.setData(ClipboardData(text: missingText)),
          duration: const Duration(seconds: 8),
          icon: FluentIcons.warning_24_regular,
        );
      }
    } else {
      showToast(context, resultText);
    }
  }

  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    var field = StringBuffer();
    var quoted = false;

    for (var index = 0; index < input.length; index++) {
      final character = input[index];
      if (character == '"') {
        if (quoted && index + 1 < input.length && input[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character == ',' && !quoted) {
        row.add(field.toString());
        field = StringBuffer();
      } else if ((character == '\n' || character == '\r') && !quoted) {
        if (character == '\r' &&
            index + 1 < input.length &&
            input[index + 1] == '\n') {
          index++;
        }
        row.add(field.toString());
        field = StringBuffer();
        if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        field.write(character);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      if (row.any((value) => value.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.importSpotifyPlaylistTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n!.importSpotifyPlaylistInstructions),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => launchURL(
                Uri.parse('https://www.chosic.com/spotify-playlist-exporter/'),
              ),
              icon: const Icon(FluentIcons.open_24_regular),
              label: Text(context.l10n!.openChosicExporter),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _chooseFile,
              icon: const Icon(FluentIcons.document_add_24_regular),
              label: Text(_fileName ?? context.l10n!.chooseCsvFile),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _playlistNameController,
              enabled: !_isImporting,
              decoration: InputDecoration(
                labelText: '${context.l10n!.playlistName} *',
                hintText: context.l10n!.spotifyPlaylistNameHint,
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _csvController,
              enabled: !_isImporting,
              minLines: 10,
              maxLines: 18,
              decoration: InputDecoration(
                labelText: context.l10n!.pasteCsv,
                hintText: context.l10n!.spotifyCsvHint,
                alignLabelWithHint: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isImporting ? null : _importPlaylist,
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(FluentIcons.arrow_upload_24_regular),
              label: Text(
                _isImporting
                    ? context.l10n!.spotifyPlaylistImporting
                    : context.l10n!.importPlaylist,
              ),
            ),
            const SizedBox(height: MiniPlayer.playerHeight + 24),
          ],
        ),
      ),
    );
  }
}
