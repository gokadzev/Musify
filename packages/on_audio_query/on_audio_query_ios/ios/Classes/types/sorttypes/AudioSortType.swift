import MediaPlayer

public func checkAudioSortType(sortType: Int) -> MPMediaGrouping {
    switch sortType {
    case 0:
        return MPMediaGrouping.title
    case 1:
        return MPMediaGrouping.artist
    case 2:
        return MPMediaGrouping.album
    default:
        return MPMediaGrouping.title
    }
}
