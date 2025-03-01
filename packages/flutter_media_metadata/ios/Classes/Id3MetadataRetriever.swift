import AVFoundation
import Foundation

public final class Id3MetadataRetriever: MetadataRetrieverProtocol {

  // borrowed from https://android.googlesource.com/platform/frameworks/base.git/+/refs/heads/master/media/java/android/media/MediaMetadataRetriever.java
  private static let standardGenres: [String] = [
    // These are the official ID3v1 genres.
    "Blues",
    "Classic Rock",
    "Country",
    "Dance",
    "Disco",
    "Funk",
    "Grunge",
    "Hip-Hop",
    "Jazz",
    "Metal",
    "New Age",
    "Oldies",
    "Other",
    "Pop",
    "R&B",
    "Rap",
    "Reggae",
    "Rock",
    "Techno",
    "Industrial",
    "Alternative",
    "Ska",
    "Death Metal",
    "Pranks",
    "Soundtrack",
    "Euro-Techno",
    "Ambient",
    "Trip-Hop",
    "Vocal",
    "Jazz+Funk",
    "Fusion",
    "Trance",
    "Classical",
    "Instrumental",
    "Acid",
    "House",
    "Game",
    "Sound Clip",
    "Gospel",
    "Noise",
    "AlternRock",
    "Bass",
    "Soul",
    "Punk",
    "Space",
    "Meditative",
    "Instrumental Pop",
    "Instrumental Rock",
    "Ethnic",
    "Gothic",
    "Darkwave",
    "Techno-Industrial",
    "Electronic",
    "Pop-Folk",
    "Eurodance",
    "Dream",
    "Southern Rock",
    "Comedy",
    "Cult",
    "Gangsta",
    "Top 40",
    "Christian Rap",
    "Pop/Funk",
    "Jungle",
    "Native American",
    "Cabaret",
    "New Wave",
    "Psychadelic",
    "Rave",
    "Showtunes",
    "Trailer",
    "Lo-Fi",
    "Tribal",
    "Acid Punk",
    "Acid Jazz",
    "Polka",
    "Retro",
    "Musical",
    "Rock & Roll",
    "Hard Rock",
    // These were made up by the authors of Winamp and later added to the ID3 spec.
    "Folk",
    "Folk-Rock",
    "National Folk",
    "Swing",
    "Fast Fusion",
    "Bebob",
    "Latin",
    "Revival",
    "Celtic",
    "Bluegrass",
    "Avantgarde",
    "Gothic Rock",
    "Progressive Rock",
    "Psychedelic Rock",
    "Symphonic Rock",
    "Slow Rock",
    "Big Band",
    "Chorus",
    "Easy Listening",
    "Acoustic",
    "Humour",
    "Speech",
    "Chanson",
    "Opera",
    "Chamber Music",
    "Sonata",
    "Symphony",
    "Booty Bass",
    "Primus",
    "Porn Groove",
    "Satire",
    "Slow Jam",
    "Club",
    "Tango",
    "Samba",
    "Folklore",
    "Ballad",
    "Power Ballad",
    "Rhythmic Soul",
    "Freestyle",
    "Duet",
    "Punk Rock",
    "Drum Solo",
    "A capella",
    "Euro-House",
    "Dance Hall",
    // These were made up by the authors of Winamp but have not been added to the ID3 spec.
    "Goa",
    "Drum & Bass",
    "Club-House",
    "Hardcore",
    "Terror",
    "Indie",
    "BritPop",
    "Afro-Punk",
    "Polsk Punk",
    "Beat",
    "Christian Gangsta Rap",
    "Heavy Metal",
    "Black Metal",
    "Crossover",
    "Contemporary Christian",
    "Christian Rock",
    "Merengue",
    "Salsa",
    "Thrash Metal",
    "Anime",
    "Jpop",
    "Synthpop",
  ]

  let metadataItems: [AVMetadataItem]

  private(set) public var trackNumber: Int?
  private(set) public var albumLength: Int?
  private(set) public var discNumber: Int?
  private(set) public var totalDisc: Int?

  init(_ metadataItems: [AVMetadataItem]) {
    self.metadataItems = metadataItems

    parseTrackNumber()
    parseDiscNumber()
  }

  private func parseTrackNumber() {
    if let data = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataTrackNumber
    })?.stringValue {
      let trck = data.components(separatedBy: "/")
      if let trackNumberString = trck.first, let trackNumber = Int(trackNumberString) {
        self.trackNumber = trackNumber
      }

      if let albumLengthString = (trck.count == 2 ? trck.last : nil),
        let albumLength = Int(albumLengthString)
      {
        self.albumLength = albumLength
      }
    }
  }

  private func parseDiscNumber() {
    if let data = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataPartOfASet
    })?.stringValue {
      let tpos = data.components(separatedBy: "/")
      if let discNumberString = tpos.first, let discNumber = Int(discNumberString) {
        self.discNumber = discNumber
      }

      if let totalDiscString = (tpos.count == 2 ? tpos.last : nil),
        let totalDisc = Int(totalDiscString)
      {
        self.totalDisc = totalDisc
      }
    }
  }

  func getTrackName() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataTitleDescription
    })?.stringValue
  }

  func getArtistNames() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataLeadPerformer
    })?.stringValue
  }

  func getAlbumName() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataAlbumTitle
    })?.stringValue
  }

  func getAlbumArtistName() -> String? {
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.id3MetadataBand })?
      .stringValue
  }

  func getTrackNumber() -> String? {
    guard let trackNumber = trackNumber else {
      return nil
    }

    return String(trackNumber)
  }

  func getAlbumLength() -> String? {
    guard let albumLength = albumLength else {
      return nil
    }

    return String(albumLength)
  }

  func getYear() -> String? {
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.id3MetadataYear })?
      .stringValue
  }

  func getGenre() -> String? {
    guard
      let tcon = metadataItems.first(where: {
        $0.identifier == AVMetadataIdentifier.id3MetadataContentType
      })?.stringValue,
      let genreIndex = Int(tcon), genreIndex < Id3MetadataRetriever.standardGenres.count
    else {
      return nil
    }

    return Id3MetadataRetriever.standardGenres[genreIndex]
  }

  func getAuthorName() -> String? {
    // NOTE: compatible with Android. Return lyricist as author
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.id3MetadataLyricist }
    )?.stringValue
  }

  func getWriterName() -> String? {
    // unimplemented
    return nil
  }

  func getDiscNumber() -> String? {
    guard let discNumber = discNumber else {
      return nil
    }
    return String(discNumber)
  }

  func getAlbumArt() -> Data? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.id3MetadataAttachedPicture
    })?.dataValue
  }
}
