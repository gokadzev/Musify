import MediaPlayer

public func checkAlbumSortType(sortType: Int) -> MPMediaGrouping {
    switch sortType {
    case 1:
        return MPMediaGrouping.album
    case 2:
        return MPMediaGrouping.artist
    default:
        return MPMediaGrouping.album
    }
}
