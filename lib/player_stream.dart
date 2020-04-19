part of sound_stream;

class PlayerStream {
  static final PlayerStream _instance = PlayerStream._internal();
  factory PlayerStream() => _instance;

  final _playerStatusController =
      StreamController<SoundStreamStatus>.broadcast();

  PlayerStream._internal() {
    SoundStream();
    _eventsStreamController.stream.listen(_eventListener);
    _playerStatusController.add(SoundStreamStatus.Unset);
  }

  Future<dynamic> initialize({int sampleRate = 16000, bool showLogs = false}) =>
      _methodChannel.invokeMethod("initializePlayer", {
        "sampleRate": sampleRate,
        "showLogs": showLogs,
      });

  Future<dynamic> start() => _methodChannel.invokeMethod("startPlayer");

  Future<dynamic> stop() => _methodChannel.invokeMethod("stopPlayer");

  Future<dynamic> writeChunk(Uint8List data) => _methodChannel
      .invokeMethod("writeChunk", <String, dynamic>{"data": data});

  Stream<SoundStreamStatus> get status => _playerStatusController.stream;

  void _eventListener(dynamic event) {
    if (event == null) return;
    final String eventName = event["name"] ?? "";
    switch (eventName) {
      case "playerStatus":
        final String status = event["data"] ?? "Unset";
        _playerStatusController.add(SoundStreamStatus.values.firstWhere(
          (value) => _enumToString(value) == status,
          orElse: () => SoundStreamStatus.Unset,
        ));
        break;
    }
  }
}
