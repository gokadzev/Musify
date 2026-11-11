import 'package:flutter_test/flutter_test.dart';
import 'package:musify/widgets/song_selection_controller.dart';

Map _song(String ytid) => {'ytid': ytid, 'title': 'Song $ytid'};

void main() {
  late SongSelectionController controller;

  setUp(() {
    controller = SongSelectionController();
  });

  tearDown(() {
    controller.dispose();
  });

  test('a long press enters selection mode on the song it was made on', () {
    expect(controller.isActive, isFalse);

    controller.start(_song('2'));

    expect(controller.isActive, isTrue);
    expect(controller.selectedCount, 1);
    expect(controller.isSelected(_song('2')), isTrue);
  });

  test('songs are kept in the order they were ticked, not in list order', () {
    controller
      ..start(_song('3'))
      ..toggle(_song('2'))
      ..toggle(_song('6'))
      ..toggle(_song('1'));

    expect(controller.selectedSongs.map((song) => song['ytid']), [
      '3',
      '2',
      '6',
      '1',
    ]);
  });

  test('ticking a song again unticks it, and re-ticking puts it last', () {
    controller
      ..start(_song('1'))
      ..toggle(_song('2'))
      ..toggle(_song('1'))
      ..toggle(_song('1'));

    expect(controller.selectedSongs.map((song) => song['ytid']), ['2', '1']);
  });

  test('select all appends the unticked songs in list order', () {
    controller
      ..start(_song('3'))
      ..selectAll([_song('1'), _song('2'), _song('3')]);

    expect(controller.selectedSongs.map((song) => song['ytid']), [
      '3',
      '1',
      '2',
    ]);
  });

  test('leaving selection mode forgets what was ticked', () {
    controller
      ..start(_song('1'))
      ..toggle(_song('2'))
      ..exit();

    expect(controller.isActive, isFalse);
    expect(controller.hasSelection, isFalse);
  });
}
