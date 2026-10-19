# Musify desktop compatibility patches

Vendored from `just_audio_media_kit` 2.1.0 (Pato05/just_audio_media_kit),
under the accompanying Unlicense. Keep this patch small and review it when
updating the package.

- Flatten nested concatenating/looping sources before opening the MPV playlist.
  just_audio 0.10 adds a root concatenation around Musify's SponsorBlock clips.
- Preserve HTTP headers when converting clipped sources, including YouTube's
  client-specific headers.
- Disable MPV's disk cache before opening media by default. The memory buffer
  remains enabled; callers can opt in with `JustAudioMediaKit.diskCache`.

These changes apply to the desktop backend; Android's player is unchanged.
