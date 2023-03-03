import MediaPlayer

public func checkAudioType(sortType: Int) -> UInt? {
    switch sortType {
    case 0:
        return MPMediaType.music.rawValue
    case 3:
        return MPMediaType.podcast.rawValue
    case 5:
        return MPMediaType.audioBook.rawValue
    default:
        return nil
    }
}
