# sound_stream

_This plugin is still in early development stage_

A Flutter plugin started from my own needs: Stream audio data from Mic and data to Audio engine without using a file. We can use it to stream audio via network or use it with STT/TTS functions.

Current features:

* Provides stream of data from mic (Uint8List)
* Player that receive stream of raw sound data (Uint8List)
* Support both Android and iOS (cross-platform)
* Recorder & Player can work simultaneously

Limitations:
* Only support PCM 16bit Mono (for now)
* Data type send/received from stream must be Uint8List. ([Because of this Flutter's limitation](https://flutter.dev/docs/development/platform-integration/platform-channels?tab=ios-channel-swift-tab#codec))

To-do list:
* Support more audio formats
* Support more platforms (Windows, macOS, Web)
* Current code might be messy. Should clean it up (someday)