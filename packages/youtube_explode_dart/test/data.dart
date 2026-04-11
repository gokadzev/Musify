// From: https://github.com/Tyrrrz/YoutubeExplode/blob/master/YoutubeExplode.Tests/TestData/VideoIds.cs

enum VideoIdData {
  normal('mKdjycj-7eE'),
  unlisted('UGh4_HsibAE'),
  private('pb_hHv3fByo'),
  deleted('qld9w0b-1ao'),
  embedRestrictedByYouTube('_kmeFXjjGfk'),
  embedRestrictedByAuthor('MeJVWBSsPAY'),
  ageRestrictedViolent('rXMX4YJ7Lks'),
  ageRestrictedSexual('SkRSXFQerZs'),
  ageRestrictedEmbedRestricted('hySoCSoH-g8'),
  requiresPurchase('p3dDcKOFXQg'),
  liveStream('jfKfPfyJRdk'),
  liveStreamRecording('rsAAeyAr-9Y'),
  withBrokenTitle('4ZJWv6t-PfY'),
  withHighQualityStreams('V5Fsj_sCKdg'),
  withOmnidirectionalStreams('-xNN-bJQ4vI'),
  withHighDynamicRangeStreams('vX2vsvdq8nw'),
  withClosedCaptions('YltHGKX80Y8'),
  withBrokenClosedCaptions('1VKIIw05JnE'),
  // used only for testing music data extraction
  music('jNm_wrWquPs');

  const VideoIdData(this.id);

  final String id;

  @override
  String toString() => '$name($id)';

  // Videos whose metadata can be fetched.
  static const valid = [
    normal,
    unlisted,
    embedRestrictedByYouTube,
    embedRestrictedByAuthor,
    ageRestrictedViolent,
    ageRestrictedSexual,
    ageRestrictedEmbedRestricted,
    requiresPurchase,
    liveStream,
    liveStreamRecording,
    withBrokenTitle,
    withHighQualityStreams,
    withOmnidirectionalStreams,
    withHighDynamicRangeStreams,
    withClosedCaptions,
    withBrokenClosedCaptions,
  ];

  // Videos that have a viewable watch page without any restriction.
  static const validWatchpage = [
    normal,
    unlisted,
    embedRestrictedByYouTube,
    embedRestrictedByAuthor,
    ageRestrictedEmbedRestricted,
    liveStreamRecording,
    withBrokenTitle,
    withHighQualityStreams,
    withOmnidirectionalStreams,
    withHighDynamicRangeStreams,
    withClosedCaptions,
    withBrokenClosedCaptions,
  ];

  // Videos whose streams can be fetched.
  static const playable = [
    ...VideoIdData.validWatchpage,
/*
    Currently YT has disabled unlogged clients from fetching age restricted videos.
    ageRestrictedViolent,
    ageRestrictedSexual,*/
  ];

  // Cannot fetch metadata or streams.
  static const invalid = [
    deleted,
    private,
  ];
}
