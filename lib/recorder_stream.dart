part of sound_stream;

class RecorderStream {
  static final RecorderStream _instance = RecorderStream._internal();
  factory RecorderStream() => _instance;

  final _audioStreamController = StreamController<Uint8List>.broadcast();

  final _recorderStatusController =
      StreamController<SoundStreamStatus>.broadcast();

  RecorderStream._internal() {
    SoundStream();
    _eventsStreamController.stream.listen(_eventListener);
    _recorderStatusController.add(SoundStreamStatus.Unset);
    _audioStreamController.add(Uint8List(0));
  }

  Future<dynamic> initialize({int sampleRate = 16000, bool showLogs = false}) =>
      _methodChannel.invokeMethod<dynamic>("initializeRecorder", {
        "sampleRate": sampleRate,
        "showLogs": showLogs,
      });

  Future<dynamic> start() =>
      _methodChannel.invokeMethod<dynamic>("startRecording");

  Future<dynamic> stop() =>
      _methodChannel.invokeMethod<dynamic>("stopRecording");

  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<SoundStreamStatus> get status => _recorderStatusController.stream;

  void _eventListener(dynamic event) {
    if (event == null) return;
    final String eventName = event["name"] ?? "";
    switch (eventName) {
      case "dataPeriod":
        final Uint8List audioData =
            Uint8List.fromList(event["data"]) ?? Uint8List(0);
        if (audioData.isNotEmpty) _audioStreamController.add(audioData);
        break;
      case "recorderStatus":
        final String status = event["data"] ?? "Unset";
        _recorderStatusController.add(SoundStreamStatus.values.firstWhere(
          (value) => _enumToString(value) == status,
          orElse: () => SoundStreamStatus.Unset,
        ));
        break;
    }
  }
}
