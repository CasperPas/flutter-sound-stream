library sound_stream;

import 'dart:async';
import 'package:flutter/services.dart';

part 'recorder_stream.dart';
part 'player_stream.dart';

const MethodChannel _methodChannel =
    const MethodChannel('vn.casperpas.sound_stream:methods');

/// Shared broadcast controller for platform events.
/// Each component (RecorderStream, PlayerStream) manages its own subscription.
/// This controller is closed only when explicitly requested via SoundStream.dispose().
final _eventsStreamController = StreamController<dynamic>.broadcast();

/// Exception thrown when the native plugin reports an error.
class SoundStreamException implements Exception {
  /// Human-readable error message from the native side.
  final String message;

  /// The underlying [PlatformException], if available.
  final PlatformException? cause;

  SoundStreamException(this.message, [this.cause]);

  @override
  String toString() => 'SoundStreamException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Wrap a platform channel call and re-throw as [SoundStreamException].
Future<T?> _invoke<T extends Object?>(String method, [dynamic arguments]) async {
  try {
    return await _methodChannel.invokeMethod<T>(method, arguments);
  } on PlatformException catch (e) {
    throw SoundStreamException('Native error: ${e.message}', e);
  }
}

enum SoundStreamStatus {
  Unset,
  Initialized,
  Playing,
  Stopped,
}

class SoundStream {
  static final SoundStream _instance = SoundStream._internal();
  factory SoundStream() => _instance;
  SoundStream._internal() {
    _methodChannel.setMethodCallHandler(_onMethodCall);
  }

  /// Return [RecorderStream] instance (Singleton).
  RecorderStream get recorder => RecorderStream();

  /// Return [PlayerStream] instance (Singleton).
  PlayerStream get player => PlayerStream();

  /// Dispose the shared event controller.
  /// Only call when both recorder and player are no longer needed.
  void dispose() {
    _eventsStreamController.close();
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "platformEvent":
        _eventsStreamController.add(call.arguments);
        break;
    }
    return null;
  }
}

String _enumToString(Object o) => o.toString().split('.').last;
