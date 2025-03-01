import AVFoundation
import Foundation

public final class ItunesMetadataRetriever: MetadataRetrieverProtocol {
  let metadataItems: [AVMetadataItem]

  private(set) public var trackNumber: Int?
  private(set) public var albumLength: Int?
  private(set) public var discNumber: Int?
  private(set) public var totalDisc: Int?
  private(set) public var genre: String?

  init(_ metadataItems: [AVMetadataItem]) {
    self.metadataItems = metadataItems

    parseTrackNumber()
    parseDiscNumber()
    parseGenre()
  }

  private func parseTrackNumber() {
    // Note: https://stackoverflow.com/a/48709757
    if let data = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataTrackNumber
    })?.dataValue, data.count == 8 {
      let trackArray = Array(data[2...3])
      let trackData = Data(bytes: trackArray, count: trackArray.count)
      trackNumber = Int(Int16(bigEndian: trackData.withUnsafeBytes { $0.load(as: Int16.self) }))

      let totalTrackArray = Array(data[4...5])
      let totalTrackData = Data(bytes: totalTrackArray, count: totalTrackArray.count)
      albumLength = Int(
        Int16(bigEndian: totalTrackData.withUnsafeBytes { $0.load(as: Int16.self) }))
    }
  }

  private func parseDiscNumber() {
    // REVIEW: based on https://stackoverflow.com/a/48709757
    if let data = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataDiscNumber
    })?.dataValue, data.count == 6 {
      let discNumberArray = Array(data[2...3])
      let discNumberData = Data(bytes: discNumberArray, count: discNumberArray.count)
      discNumber = Int(Int16(bigEndian: discNumberData.withUnsafeBytes { $0.load(as: Int16.self) }))

      let totalDiscArray = Array(data[4...5])
      let totalDiscData = Data(bytes: totalDiscArray, count: totalDiscArray.count)
      totalDisc = Int(Int16(bigEndian: totalDiscData.withUnsafeBytes { $0.load(as: Int16.self) }))
    }
  }

  private func parseGenre() {
    if let userGenre = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataUserGenre
    })?.stringValue {
      genre = userGenre
      return
    }

    if let predefinedGenre = metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataPredefinedGenre
    })?.dataValue, predefinedGenre.count == 2 {
      let genreArray = Array(predefinedGenre)
      let genreData = Data(bytes: genreArray, count: genreArray.count)
      let genreNumber = Int(Int16(bigEndian: genreData.withUnsafeBytes { $0.load(as: Int16.self) }))
      genre = PredefinedGenre.allCases.first(where: { $0.number == genreNumber })?.name
      return
    }
  }

  func getTrackName() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataSongName
    })?.stringValue
  }

  func getArtistNames() -> String? {
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.iTunesMetadataArtist }
    )?.stringValue
  }

  func getAlbumName() -> String? {
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.iTunesMetadataAlbum }
    )?.stringValue
  }

  func getAlbumArtistName() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataAlbumArtist
    })?.stringValue
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
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataReleaseDate
    })?.stringValue
  }

  func getGenre() -> String? {
    return genre
  }

  func getAuthorName() -> String? {
    // REVIEW:
    return metadataItems.first(where: { $0.identifier == AVMetadataIdentifier.iTunesMetadataAuthor }
    )?.stringValue
  }

  func getWriterName() -> String? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataComposer
    })?.stringValue
  }

  func getDiscNumber() -> String? {
    guard let discNumber = discNumber else {
      return nil
    }
    return String(discNumber)
  }

  func getAlbumArt() -> Data? {
    return metadataItems.first(where: {
      $0.identifier == AVMetadataIdentifier.iTunesMetadataCoverArt
    })?.dataValue
  }
}

extension ItunesMetadataRetriever {
  ///
  /// macOS Music.app predefined genre
  ///
  /// Note: "Blues/R&B", "Books & Spoken", "Children's Music", "Hip Hop/Rap", "Holiday", "Religious",
  ///       "Unclassifiable" and "World" are omitted because they had not genre number.
  ///
  enum PredefinedGenre: CaseIterable {
    case country, dance, jazz, newAge, pop, rock, techno, industrial, alternative, soundtrack,
      trance, classical, house, electronic, folk, easyListening

    var name: String {
      switch self {
      case .country: return "Country"
      case .dance: return "Dance"
      case .jazz: return "Jazz"
      case .newAge: return "New Age"
      case .pop: return "Pop"
      case .rock: return "Rock"
      case .techno: return "Techno"
      case .industrial: return "Industrial"
      case .alternative: return "Alternative"
      case .soundtrack: return "Soundtrack"
      case .trance: return "Trance"
      case .classical: return "Classical"
      case .house: return "House"
      case .electronic: return "Electronic"
      case .folk: return "Folk"
      case .easyListening: return "Easy Listening"
      }
    }

    var number: Int {
      switch self {
      case .country: return 3
      case .dance: return 4
      case .jazz: return 9
      case .newAge: return 11
      case .pop: return 14
      case .rock: return 18
      case .techno: return 19
      case .industrial: return 20
      case .alternative: return 21
      case .soundtrack: return 25
      case .trance: return 32
      case .classical: return 33
      case .house: return 36
      case .electronic: return 53
      case .folk: return 81
      case .easyListening: return 99
      }
    }
  }
}
