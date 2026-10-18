# Desktop builds

Use the Flutter version required by `pubspec.yaml`.

- Linux: install clang, CMake, Ninja, pkg-config, GTK 3 and liblzma development packages, then run `flutter pub get` and `flutter build linux --release`.
- Windows: install Visual Studio with Desktop development with C++, then run `flutter pub get` and `flutter build windows --release`.

Distribute the complete release bundle, including native libraries and data files.
The desktop workflow builds both platforms and uploads their bundles as artifacts.

The local `just_audio_media_kit` package retains its Unlicense. Its compatibility
patches support nested SponsorBlock clips, preserve their HTTP headers and keep
buffering in memory without MPV's disk cache. Review the patch when updating it.

Native playback tests use a local HTTP audio fixture. Set `MUSIFY_TEST_LIBMPV` to
libmpv's absolute path and run `flutter test test/desktop_audio_native_test.dart`.
