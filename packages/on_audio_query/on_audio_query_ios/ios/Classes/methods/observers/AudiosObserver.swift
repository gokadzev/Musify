import MediaPlayer

class AudiosObserver : NSObject, FlutterStreamHandler {
    
    // Main parameters
    private var query: AudiosQuery?
    private var sink: FlutterEventSink?
    private let library = MPMediaLibrary.default()
    private let notification = NotificationCenter.default
    
    // [Internal] variable to detect when the observer is running or not.
    private var pIsRunning: Bool = false
    // [Get] variable to detect when the observer is running or not.
    var isRunning: Bool {
        get { pIsRunning }
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Define the [sink].
        // The sink is used to define/send a event(change) or error.
        sink = events
        
        // Setup the 'query' class.
        query = AudiosQuery(
            sink: self.sink,
            args: arguments as? [String: Any]
        )
        
        // If 'observe' method is called and the observer is already running
        // don't 'init' another notification observer.
        if !pIsRunning {
            // 'Tell' to library send notification when changing.
            library.beginGeneratingLibraryChangeNotifications()
            
            // Will be 'called' everytime the MPMediaLibrary change.
            // TODO: Currently will 'fire' any change. We need detect only 'audios' change.
            notification.addObserver(forName: .MPMediaLibraryDidChange, object: nil, queue: nil, using: { _ in
                self.query?.queryAudios()
            })
        }
        
        // Define the [AudiosObserver] as running.
        pIsRunning = true
        
        // Send the initial data.
        query?.queryAudios()
        
        // No errors.
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        // Define [isRunning] as false.
        pIsRunning = false
        
        // 'Tell' to library not send notification when changing.
        library.endGeneratingLibraryChangeNotifications()
        
        // Stop listening the [MPMediaLibrary].
        notification.removeObserver(
            self,
            name: .MPMediaLibraryDidChange,
            object: nil
        )
        
        // 'Cancel' the [sink] and [query].
        sink = nil
        query = nil
        
        // No erros.
        return nil
    }
}
