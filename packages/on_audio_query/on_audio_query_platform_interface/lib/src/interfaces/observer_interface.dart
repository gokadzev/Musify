/// A observer interface.
abstract class ObserverInterface {
  /// Variable to detect when the observer is running or not.
  bool get isRunning;

  /// Stream used to listen all changes.
  ///
  /// Note: If [isRunning] is false or the method [startObserver] was never called
  /// (so the internal controller is null), calling this stream will throw a [NullThrownError].
  Stream<dynamic> get stream;

  /// Method to start observing the directory.
  void startObserver(Map<String, dynamic> args);

  /// Method called everytime some file is added/removed and modified inside the
  /// directory.
  void onChange();

  /// Method called to cancel/stop listening the directory.
  void stopObserver();
}
