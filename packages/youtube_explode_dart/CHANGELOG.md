## 3.0.5
- Re-add requireWatchPage functionality to `getManifest`.
- Allow specifying deno path. Thanks to @obemu.
- Support for live urls. Thanks to @Rerurate514.

## 3.0.4
- Fix EJS exports.

## 3.0.3
- Add comment `ejs` solvers class.
- Update `tv` client.

## 3.0.2
- Implement bulk challenges solver.

## 3.0.1
- Fix issue with the `deno` signature solver where the command line arguments on some systems where too long.
- Small optimizations by reusing the already preprocessed player in the `js` solver.

## 3.0.0
- Implement `deno` js signature solver.
- Implement new interfaces for custom JS challenges solver.

## 2.5.3
- Update `android` client.
- Stop throwing when signature can't be found, instead just skip that stream.
- Fix parsing error when a collaboration video appeared in a search result.

## 2.5.2
- Add `Video.musicData` getter.

## 2.5.1
- Fix related videos api.

## 2.5.0
- Implement new function decipherer.
- Fix bug preventing fetching more than 100 videos in a playlist. Thanks to @khaled-0
- Expose header getter to `YoutubeHttpClient`. Thanks to @khaled-0


## 2.4.2
- Update safari client.
- Fix signature deciphering.

## 2.4.1
- Update IOS client.

## 2.4.0
- Update IOS client.
- Implement visitor data extraction. Port from: https://github.com/Tyrrrz/YoutubeExplode/commit/84e29bb
- Support freezed 3.0.0.

## 2.3.10
- Update dev_dependencies
- Fix #328. Shorts extraction from channel uploads.
- Skip tests that always fail on GitHub actions.

## 2.3.9
- Fix HLS extraction.
- Fix JSEngine: -, * operators.

## 2.3.8
- Simplify Playlist ID matching logic by @khaled-0 in https://github.com/Hexer10/youtube_explode_dart/pull/316
- Fix Parsing JSON response for shorts by @JorWo in https://github.com/Hexer10/youtube_explode_dart/pull/313
- Added if-null check for playlist video count by @codedbycurtis in https://github.com/Hexer10/youtube_explode_dart/pull/317
- Fixes for JSEngine.

## 2.3.7
- Fixes JSON parsing for shorts data

## 2.3.6
- Update search playlists parsing due to yt changes.
- Implement >,<,== operators for `VideoResolution`.

## 2.3.5
- Deprecated `YoutubeApiClient.tvSimpleEmbedded`.
- Improve JSEngine

## 2.3.4
- Better HLS support

## 2.3.3
- Re-implement sig deciphering.

## 2.3.2
- Implement HLS streams parsing.
- Add safari, tv, and androidVr yt clients.

## 2.3.1
- Implement small JSEngine to decipher stream signatures.
- Add channel thumbnails in search results. Thanks to  BinaryQuantumSoul. #289
- Add `requireWatchPage` parameter to `getManifest` to fetch streams without having to get the watchpage.
 
## 2.3.0+1
- Updated changelog.

## 2.3.0
- Implement `YoutubeApiClient` interface.
- Add `ytClient` parameter to `StreamClient.getManifest`.
- Implement more youtube api clients, see `StreamClient.getManifest` documentation or `youtube_api_client.dart` for more information.

## 2.2.3
- Impersonate ios client to extract manifest.

## 2.2.2
- Fix video extraction. Thanks to @bigzhu #287.

## 2.2.1
- Implement `VideoClient.get` to fetch a list of related videos given another Video.

## 2.2.0
- Implement shorts filter. Thanks to @igormidev #269.
- Implement `AudioTrack`s in `StreamInfo` to find the language of an audio track.
- Added `fullManifest` optional parameter for `StreamClient.getManifest` to fetch a manifest with more streams, including all the languages provided by YouTube.
- Fix issue where 1440p videos would be detected as 144p.
- Fix endless loop with fetching some playlists.

## 2.1.0
- BREAKING CHANGE: 
    - In `getUploadsFromPage`: the `videoSorting` parameter is now a named parameter
- Shorts filter possibility added in `getUploadsFromPage`.

## 2.0.4
- Fix issue when parsing dates formatted as "Streamed <q> <unit> ago" due to a leading whitespace. #265

## 2.0.3
- Better performance for iterating through closed captions elements. #251
- Add publishDate and viewCount for playlists. #240
- Fix fetching of YT music playlists. #261
- Fix like count extraction.

## 2.0.2
- Implement YT Handles.
- Deprecated ChannelLink icon's uri, they are no longer provided by YT.
- Remove unused left-over code.

## 2.0.1
- Linter fixes.

## 2.0.0
- BREAKING CHANGE: Required at least dart 3.00
- Fixes for dart3
- Deprecated: `BaseSearchContent`; now the search apis return a freezed union type instead of a common class.
- Deprecated: Renamed methods of the `SearchPlaylist` class: `playlistId`, `playlistTitle` and `playlistVideoCount` are own named `id`, `title`, and `videoCount`.
- Fixes for violence age restricted videos.
- Replaced deprecated `XmlElement.text` to `innerText`.
- Implemented common super class `BasePagedList` for `CommentsList`, `VideoSearchList`, `ChannelUploadsList` and `SearchList`.
- Fix for some streams returning 403 status code.
- Fix fetching of restricted videos.
- 

## 1.12.4
- Fix #231: Slow download speed.

## 1.12.3
- Fix #229: error when getting comments from a video with comments disabled. Not it returns null.
- Fix error when getting comments of a with no comments. Now it returns an empty list.

## 1.12.2
- Fix #228: error when getting videos from the uploads page. 

## 1.12.1
- Fix #216 comments api.
- Export `BaseSearchContent`, thanks to @RubinRaithel.
- Updated tests.

## 1.12.0
- Fix #207: Allow every character to be present in a username.
- Fix shorts. Thanks to @prateekmedia.
- Add raw upload date on Video model. Thanks to @Nikos Portolos.
- Fix null values for selected fields when parsing chanel uploads. Thanks to @Nikos Portolos.

## 1.11.0
- BREAKING CHANGE: Removed `SearchClient.getVideosFromPage`, use `SearchClient.search` or `SearchClient.search.search`.
- BREAKING CHANGE: `SearchClient.search` now returns `VideoSearchList` (List<Video>).
- BREAKING CHANGE: Remove the `filter` variable, now use `SearchFilter`.
- To get the filters use static access on `FeatureFilters`, `UploadDateFilter`, `TypesFilter`, `DurationFilters`, `SortFilters`.
- Introduced `SearchClient.searchContent` to search for videos, channels and playlists.
- Introduced `SearchClient.searchRaw` to manually parse the content and also get related videos and estimated results.
- Fix #197: Fixed `withHighestBitrate()`.
- Introduced: `List<VideoStreamInfo>.bestQuality`.

## 1.10.10+2
- Fix #194: Now closed-captions allow malformed utf8 as well.

## 1.10.10+1
- Deprecated `withHighestBitrate()` in favour of `bestQuality`. 

## 1.10.10
- Fix issue #136: Add `bannerUrl` getter for `Channel`.
- Fix `ChannelClient.getByUsername` for `youtube.com/c/XXXX` channels.
- Fix issue #192: Make nullable ChannelAboutPage's properties.

## 1.10.9
- Fix issue #180: YouTube throttling videos. - Thanks to @itssidhere.

## 1.10.8
- Added the following aliases: yt.videos.streams (instead of yt.videos.streamsClient) and yt.videos.comments (instead of yt.videos.commentsClient)
- Re-add more test cases.
- Implement `.describe()` on List<StreamInfo> which prints a formatted list like `youtube-dl -F` option. T
- Fix muxed video extraction ( #172 )
- Better dis/likes video extraction.

## 1.10.7+1
- Fix tests.
- Remove debug leftovers.

## 1.10.7
- Fix the error of incomplete data loading on the Android emulator.
- Fix error when the http-client is closed and the request is still running.
- Fix extraction for DASH streams.

## 1.10.6
- Implement `Playlist.videoCount`.

## 1.10.5+1
- Export `CommentsList` class.


## 1.10.5
- Implement: `CommentsList.totalLength` (#150), `Comment.isHearted` (#151).

## 1.10.4
- Fix infinite loop when getting channel uploads.

## 1.10.3
- Implement Embedded client. Thanks to @89z

## 1.10.2
- Better comments API: Implemented API to fetch more comments & replies.

## 1.10.1
- Fix issue #146: Closed Captions couldn't be extracted anymore.
- Code cleanup.


## 1.10.0
- Fix issue #144: get_video_info was removed from yt.
- Min sdk version now is 2.13.0
- BREAKING CHANGE: New comments API implementation.

## 1.9.10
- Close #139: Implement Channel.subscribersCount.

## 1.9.9
- Fix issue #134 (Error when getting the hls manifest from a livestream)

## 1.9.8+1
- Fix example

## 1.9.8
- Fix issue #131 (Cannot get publishDate or uploadDate)

## 1.9.7
- Fix issue #135 (Cannot use getUploadsFromPage on a channel with no uploads).

## 1.9.6
- Fix comment client.
- Fix issue #130 (ClosedCaptions)


## 1.9.5
- Temporary for issue #130

## 1.9.4
- Fix issue #126

## 1.9.3+2
- Fix `ChannelUploadsList`.

## 1.9.3+1
- Export `ChannelUploadsList`.

## 1.9.3
- `getUploadsFromPage` now returns an instance of `ChannelUploadsList`.

## 1.9.2+2
- Fix `videoThumbnail` in `ChannelVideo`.

## 1.9.2+1
- Implement `videoThumbnail` in `ChannelVideo`.

## 1.9.2
- Implement `videoDuration` in `ChannelVideo`.

## 1.9.1
- Bug fixes (due to YouTube changes)

## 1.9.0
- Support nnbd (dart 1.12)
- New api: `getQuerySuggestions`: Returns the suggestions youtube provides while making a video search.
- Now playlists with more than 100 videos return all the videos. Thanks to @ATiltedTree.
- Implemented `ChannelAboutPage`, check the tests their usage.
- Implement filters for `search.getVideos`. See `filter` getter.
- Now video's from search queries return the channel id.
- Implemented publishDate for videos. Thanks to @mymikemiller , PR: #115.I t

## 1.8.0
- Fixed playlist client.
- Fixed search client.
- `search.getVideos` now returns a `Video` instance.
- Implemented `SearchList`.

## 1.8.0-beta.4
- Removed debug message

## 1.8.0-beta.3
- Fixed playlists

## 1.8.0-beta.2
- `search.getVideos` now returns a `Video` instance.

## 1.8.0-beta.1
- Removed deprecation of `Video`.
- Exported `SearchList`.

## 1.8.0-beta.0
- Fix video search:
    Now `getVideos` returns `SearchList` holding 20 videos. `SearchList.nextPage()` can be called to get the next batch of videos.

## 1.7.5
- Fix auto translated closed captions ( #50 )
- Deprecated `autoGenerated` from `getManifest`.
- Added `autoGenerated` parameter to `manifest.getByLanguage(...)`

## 1.7.4
- Fix slow download ( #92 )
- Fix stream retrieving on some videos ( #90 )
- Updates tests

## 1.7.3
- Fix exceptions on some videos.
- Closes #89, #88

## 1.7.2
- Export Closed Captions Members.
- Fix #86

## 1.7.1
- `ClosedCaptionTrackInfo` and it's members are now json serializable.

## 1.7.0
- BREAKING CHANGES: `ClosedCaptionManifest.getByLanguage` now returns a List.
- New Enum-Like class: `ClosedCaptionFormat`, which holds all the available YouTube subtiles format.
- `ClosedCaptionManifest.getByLanguage` now has a parameter named `format`.
- `ClosedCaptionClient.getManifest` now has a parameter named `autoGenerated`
- Fix: #82, #83

## 1.6.2
- Bug fixes: #80

## 1.6.1
- Add thumbnail to `SearchVideo` thanks to @shinyford !

## 1.6.0
- BREAKING CHANGE: Renamed `getVideosAsync` to `getVideos`.
- Implemented `getVideosFromPage` which supersedes `queryFromPage`.
- Implemented JSON Classes for reverse engineer.
- Added `forceWatchPage` to the video client to assure the fetching of the video page. (ATM useful only if using the comments api)
- Remove adaptive streams. These are not used anymore.
- Implement `channelClient.getAboutPage` and `getAboutPageByUsername` to fetch data from a channel's about page.

## 1.5.2
- Fix extraction for same videos (#76)

## 1.5.1
- Fix Video Search: https://github.com/Tyrrrz/YoutubeExplode/issues/438

## 1.5.0
- BREAKING CHANGE: Renamed `Container` class to `StreamContainer` to avoid conflicting with Flutter `Container`. See #66

## 1.4.4
- Expose HttpClient in APIs
- Fix #55: Typo in README.md
- Fix #61: DartVM when the YouTube explode client is closed.

## 1.4.3
- Fix #59
- Implement for tests #47
- Better performance for VideoClient.get

## 1.4.2
- Fix Decipher error #53

## 1.4.1+3
- Fix decipherer

## 1.4.1+2
- Implement Container.toString()

## 1.4.1+1
- Bug fixes

## 1.4.1
- Implement `getUploadsFromPage` to a channel uploaded videos directly from the YouTube page.

## 1.4.0
- Add ChannelId property to Video class.
- Implement `thumbnails` for playlists. The playlist's thumbnail is the same as the thumbnail of its first video. If the playlist is empty, then this property is `null`.
- Update for age restricted videos.

## 1.3.3
- Error handling when using `getStream` if the connection fails. If it fails more than 5 times on the same request the exception will be thrown anyways.
- Caching of player source for 10 minutes.

## 1.3.2
- Minor caching changes.

## 1.3.1
- Implement caching of some results.

## 1.3.0
- Added api get youtube comments of a video.

## 1.2.3
- Fix duplicated bytes when downloading a stream. See [#41][Comment41]

## 1.2.2
- Momentarily ignore `isRateLimited()` when getting streams.

## 1.2.1

- Fixed `SearchPage.nextPage`.
- Added more tests.

## 1.2.0
- Improved documentation.
- Deprecated `StreamInfoExt.getHighestBitrate`, use list.`sortByBitrate`.
- Implemented `withHighestBitrate` and `sortByBitrate` for `StreamInfo` iterables.
- Implemented `withHighestBitrate` for `VideoStreamInfo` iterables.
- Now `sortByVideoQuality` returns a List of `T`.
- `SearchQuery.nextPage` now returns null if there is no next page.

## 1.1.0
- Implement parsing of the search page to retrieve information from youtube searches. See `SearchQuery`.


## 1.0.0
- Stable release

---

## 1.0.0-beta

- Updated to v5 of YouTube Explode for C#

## 1.0.1-beta

- Implement `SearchClient`.
- Implement `VideoStreamInfoExtension` for Iterables.
- Update `xml` dependency.
- Fixed closed caption api.

## 1.0.2-beta

- Fix video likes and dislikes count. #30
<hr>

## 0.0.1

- Initial version, created by Stagehand

## 0.0.2

- Implement channel api

## 0.0.3

- Remove `dart:io` dependency.

## 0.0.4

- Fix #3 : Head request to ge the content length
- Fix error when getting videos without any keyword.

## 0.0.5

- Implement Search Api (`SearchExtension`)

## 0.0.6

- Implement Caption Api ('CaptionExtension`)
- Add Custom Exceptions

## 0.0.7

- Implement Video Purchase error
- Implement Equatable for models

## 0.0.8

- Downgrade xml to `^3.5.0`

## 0.0.9

- Bug Fix(PR [11][11]): Use url when retrieving the video's content length.

[11]: https://github.com/Hexer10/youtube_explode_dart/pull/11

## 0.0.10

- Bug fix: Don't throw when captions are not present.
- New extension: CaptionListExtension adding `getByTime` function.

## 0.0.11

- New extension: DownloadExtension adding `downloadStream` function.

## 0.0.12

- Bug fix(#15): Fix invalid upload date.

## 0.0.13

- Bug fix(#15): Fix valid channel expression

## 0.0.14

- getChannelWatchPage and getVideoWatchPage methods are now public
- New method: getChannelIdFromVideo

## 0.0.15

- Workaround (#15): Now when a video is not available a `VideoUnavailable` exception is thrown
- Removed disable_polymer parameter when requests ( https://github.com/Tyrrrz/YoutubeExplode/issues/341 )
- Removed `dart:io` dependency

## 0.0.16

- When a video is not available(403) a `VideoStreamUnavailableException`

## 0.0.17

- Fixed bug in #23



[Comment41]: https://github.com/Hexer10/youtube_explode_dart/issues/41#issuecomment-646974990
