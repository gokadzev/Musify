# Audiotagger example

Demonstrates how to use the audiotagger plugin.

> **Actually works only on Android.**

The app has has an output widget and 3 buttons.

## Explanation

Initially the utput widget will be a `Text` widget with writed *Ready..*

By clicking *Read tags* you'll fire `tagger.readTagsAsMap` method, and the output will be showed you as a JSON string in `Text` widget.  
This widget will replace the output one.

By clicking *Read artwork* you'll fire `tagger.readArtwork` method, and the output will show you the image in the output widget.

By clicking *Write tags* you'll fire `tagger.writeTagsFromMap` method, and the output will be showed you  in `Text` widget.
The text will be *true* if the operation success, *false* instead.  
This widget will replace the output one.