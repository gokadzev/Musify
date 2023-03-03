import MediaPlayer

//
extension String {
    func isCase(ignoreCase: Bool) -> String {
        return ignoreCase == true ? self : self.lowercased()
    }
}

//
extension UInt64 {
    func getMediaCount(type: Int) -> Int {
        var cursor: MPMediaQuery? = nil
        var filter: MPMediaPropertyPredicate? = nil
        
        if type == 0 {
            filter = MPMediaPropertyPredicate.init(value: self, forProperty: MPMediaItemPropertyGenrePersistentID)
            cursor = MPMediaQuery.genres()
        } else {
            filter = MPMediaPropertyPredicate.init(value: self, forProperty: MPMediaPlaylistPropertyPersistentID)
            cursor = MPMediaQuery.playlists()
        }
        
        if cursor != nil && filter != nil {
            cursor?.addFilterPredicate(filter!)
            
            if (cursor!.collections?.count != nil) {
                return cursor!.collections!.count
            }
        }
        
        //
        return -1;
    }
}


//
extension Array where Element == [String: Any?] {
    //
    func mediaFilter(
        mediaProjection: [String?],
        toQuery: [Int: [String]],
        toRemove: [Int: [String]]
    ) -> [[String: Any?]] {
        // Define a copy of this media list.
        var copyOfMediaList = self
        
        // For every 'row' from 'toQuery', *keep* the media that contains the 'filter'.
        for (id, values) in toQuery {
            
            // If the given [id] doesn't exist. Skip to next.
            if mediaProjection[id] == nil {
                continue
            }
            
            // The [id] is a valid value. Now, for every item/word from values
            // remove all that doesn't match.
            for value in values {
                // Remove all items.
                copyOfMediaList.removeAll(where: { audios in
                    // Check if contains.
                    return audios.contains(where: { key, val in
                        // If the [key] and [projection] match, check if the value *contains*.
                        // If so, keep the 'media'. If not, remove it.
                        return key == mediaProjection[id] && !String(describing: val).contains(value)
                    })
                })
            }
        }
        
        // For every 'row' from 'toRemove', *remove* the media that contains the 'filter'.
        for (id, values) in toRemove {
            
            // If the given [id] doesn't exist. Skip to next.
            if mediaProjection[id] == nil {
                continue
            }
            
            // The [id] is a valid value. Now, for every item/word from values
            // remove all that does match.
            for value in values {
                // Remove all items.
                copyOfMediaList.removeAll(where: { audios in
                    // Check if contains.
                    return audios.contains(where: { key, val in
                        // If the [key] and [projection] match, check if the value *contains*.
                        // If so, remove the 'media'. If not, keep it.
                        return key == mediaProjection[id] && String(describing: val).contains(value)
                    })
                })
            }
        }
        
        //
        return copyOfMediaList
    }
}
