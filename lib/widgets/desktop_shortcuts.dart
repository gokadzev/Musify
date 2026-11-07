import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musify/main.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/screens/search_page.dart';
import 'package:musify/services/router_service.dart';
import 'package:musify/utilities/platform_utils.dart';

enum DesktopShortcut {
  playPause,
  next,
  previous,
  volumeUp,
  volumeDown,
  search,
  player,
}

class DesktopShortcuts extends StatelessWidget {
  const DesktopShortcuts({required this.child, this.onAction, super.key});
  final Widget child;
  final ValueChanged<DesktopShortcut>? onAction;

  static const bindings = <SingleActivator, DesktopShortcut>{
    SingleActivator(LogicalKeyboardKey.space, includeRepeats: false):
        DesktopShortcut.playPause,
    SingleActivator(
      LogicalKeyboardKey.arrowRight,
      control: true,
      includeRepeats: false,
    ): DesktopShortcut.next,
    SingleActivator(
      LogicalKeyboardKey.arrowLeft,
      control: true,
      includeRepeats: false,
    ): DesktopShortcut.previous,
    SingleActivator(LogicalKeyboardKey.arrowUp, control: true):
        DesktopShortcut.volumeUp,
    SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
        DesktopShortcut.volumeDown,
    SingleActivator(
      LogicalKeyboardKey.keyF,
      control: true,
      includeRepeats: false,
    ): DesktopShortcut.search,
    SingleActivator(
      LogicalKeyboardKey.keyP,
      control: true,
      includeRepeats: false,
    ): DesktopShortcut.player,
  };

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        final focused = FocusManager.instance.primaryFocus?.context;
        final editing =
            focused?.widget is EditableText ||
            focused?.findAncestorWidgetOfExactType<EditableText>() != null;
        for (final binding in bindings.entries) {
          if (editing && binding.value != DesktopShortcut.search) continue;
          if (binding.key.accepts(event, HardwareKeyboard.instance)) {
            (onAction ?? invoke)(binding.value);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  static void invoke(DesktopShortcut action) {
    switch (action) {
      case DesktopShortcut.playPause:
        if (audioHandler.audioPlayer.playing) {
          audioHandler.pause();
        } else {
          audioHandler.play();
        }
      case DesktopShortcut.next:
        audioHandler.skipToNext();
      case DesktopShortcut.previous:
        if (audioHandler.hasPrevious) audioHandler.skipToPrevious();
      case DesktopShortcut.volumeUp:
        audioHandler.setVolume(audioHandler.volume + 0.05);
      case DesktopShortcut.volumeDown:
        audioHandler.setVolume(audioHandler.volume - 0.05);
      case DesktopShortcut.search:
        NavigationManager.router.go(NavigationManager.searchPath);
        requestSearchFocus();
      case DesktopShortcut.player:
        final navigator = NavigationManager.parentNavigatorKey.currentState;
        if (navigator == null) return;
        var playerIsOnTop = false;
        navigator.popUntil((route) {
          playerIsOnTop = route.settings.name == nowPlayingRouteName;
          return true;
        });
        if (playerIsOnTop) {
          navigator.pop();
        } else if (audioHandler.mediaItem.value != null) {
          navigator.push(buildNowPlayingRoute());
        }
    }
  }
}
