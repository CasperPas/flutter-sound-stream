## 0.4.3
* Fix iOS: replace `fatalError` with graceful error handling in audio buffer conversion
* Fix iOS: replace `try!` on AVAudioSession with proper `do-catch` blocks
* Fix iOS: handle `AVAudioEngine.start()` errors instead of silently ignoring them
* Fix iOS: fix recorder tap re-installation lifecycle (clear isRecording before starting)
* Fix iOS: re-check permission on each call instead of caching (handles Settings changes)
* Fix Dart: dispose no longer closes shared event controller (prevents cross-component breakage)
* Fix Dart: dispose is now idempotent (safe to call multiple times)
* Fix Dart: add SoundStreamException for typed platform errors
* Fix Dart: use typed _invoke wrapper for all platform calls
* Fix Android: guard against activeResult race condition during re-initialization
* Fix Android: copy audio data before sending to prevent corruption under load
* Fix Android: properly detach record listener on engine detach
* Fix: update podspec version to 0.4.2
* Fix: add NSMicrophoneUsageDescription to iOS Info.plist
* Fix: update dead ngrok URL in example app
* Fix: add proper dispose calls in example apps

## 0.4.2
* Add flutter 3.29+ support from @beingmishra

## 0.4.1
* Fix issue #62 - Orange microphone bubble remains on iOS

## 0.4.0
* Fix some bugs reported by the community: crashes, cannot play via headsets...
* Allow to force using built-in mic & speaker

## 0.3.0
* Migrate to null-safety

## 0.2.0
* Recorder & Player can work simultaneously
* Minor code refactor

## 0.1.0+1
Refactor to match pub.dev's Health suggestions
* Add a dispose method

## 0.1.0

Cross-platform support
* Audio data can be sent from Android to iOS and vice versa.
* Player that receive stream of PCM 16bit sound data in a (Uint8List).
* Added new example: Send data via **WebSocket**
* Fixed some bugs.

## 0.0.1

Initial release
* Provides stream of data from mic (Uint8List).
* Player that receive stream of raw sound data (Uint8List).
* Support both Android and iOS.