## 1.0.0

* First release. See [ReadMe file](README.md) for informations.

## 1.0.2

* Fixed bug in `writeTags` when `artwork` field was not provided.
* Updated dependecies, examples and README.

## 1.0.3

* Increased performance.

## 1.0.4

* Solved bug of [issue #1](https://github.com/Samurai016/Audiotagger/issues/1).

## 1.0.5

* Updated documentation.

## 1.1.0

* Fixed a bug that prevented a field from being reset.
* Added new method `writeTag` to write a single tag field.
* Removed `checkPermission` flag. This will prevent problems of compatibility between Audiotagger and [Permission handler library](https://pub.dev/packages/permission_handler).
Refer to README for any information. 

## 2.0.0

* Migrated project to support Null-Safety feature.

## 2.1.0

* Fixed bug [#12](https://github.com/Samurai016/Audiotagger/issues/12).
* Improved behavior of `readTags` method.
* Migrated [`AudiotaggerPlugin.java`](https://github.com/Samurai016/Audiotagger/blob/master/android/src/main/java/com/nicolorebaioli/audiotagger/AudiotaggerPlugin.java) to [1.12 Flutter plugin APIs](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration).
* Improved testing files.

## 2.2.0

* Added `AudioFile` class (solved [issue #14](https://github.com/Samurai016/Audiotagger/issues/14)).
* Added `readAudioFile` and `readAudioFileAsMap` methods (solved [issue #14](https://github.com/Samurai016/Audiotagger/issues/14)).
* Fixed small bugs.
* Updated documentation.

## 2.2.1

* Fixed [issue #15](https://github.com/Samurai016/Audiotagger/issues/15).
* Updated documentation.