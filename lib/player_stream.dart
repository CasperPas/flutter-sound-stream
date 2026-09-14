part of sound_stream;

class PlayerStream {
  static final PlayerStream _instance = PlayerStream._internal();
  factory PlayerStream() => _instance;

  final _playerStatusController =
      StreamController<SoundStreamStatus>.broadcast();
  final _audioStreamController = StreamController<Uint8List>();

  /// Subscription to the shared events controller.
  StreamSubscription<dynamic>? _eventsSubscription;

  bool _isDisposed = false;

  PlayerStream._internal() {
    SoundStream();
    _eventsSubscription = _eventsStreamController.stream.listen(_eventListener);
    _playerStatusController.add(SoundStreamStatus.Unset);
    _audioStreamController.stream.listen((data) {
      writeChunk(data);
    });
  }

  /// Initialize Player with specified [sampleRate]
  Future<void> initialize(
          {int sampleRate = 16000, bool showLogs = false}) async {
    await _invoke('initializePlayer', {
      "sampleRate": sampleRate,
      "showLogs": showLogs,
    });
  }

  /// Player will start receiving audio chunks (PCM 16bit data)
  /// to audiostream as Uint8List to play audio.
  Future<void> start() async => await _invoke('startPlayer');

  /// Player will stop receiving audio chunks.
  Future<void> stop() async => await _invoke('stopPlayer');

  /// Push audio [data] (PCM 16bit data) to player buffer as Uint8List
  /// to play audio. Chunks will be queued/scheduled to play sequentially
  Future<void> writeChunk(Uint8List data) async =>
      await _invoke('writeChunk', <String, dynamic>{"data": data});

  /// Switching/Forcing player to use phone's speaker.
  Future<void> usePhoneSpeaker(bool value) async =>
      await _invoke('usePhoneSpeaker', <String, dynamic>{"value": value});

  /// Current status of the [PlayerStream]
  Stream<SoundStreamStatus> get status => _playerStatusController.stream;

  /// Stream's sink to receive PCM 16bit data to send to Player
  StreamSink<Uint8List> get audioStream => _audioStreamController.sink;

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

  /// Stop and close all streams. This cannot be undone.
  /// Only call this method if you don't want to use this anymore.
  /// Safe to call multiple times (idempotent).
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stop();
    _eventsSubscription?.cancel();
    _playerStatusController.close();
    _audioStreamController.close();
  }
}
