import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_stream/sound_stream.dart';

/// Set up a mock handler for the platform channel.
void mockPlatformChannel({Future<dynamic> Function(MethodCall)? handler}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      MethodChannel('vn.casperpas.sound_stream:methods');
  channel.setMockMethodCallHandler(handler ?? (call) async => null);
  addTearDown(() => channel.setMockMethodCallHandler(null));
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SoundStream', () {
    test('singleton returns same instance', () {
      expect(SoundStream(), equals(SoundStream()));
    });

    test('recorder is singleton', () {
      expect(RecorderStream(), equals(RecorderStream()));
    });

    test('player is singleton', () {
      expect(PlayerStream(), equals(PlayerStream()));
    });
  });

  group('RecorderStream', () {
    test('initialize sends correct method call with defaults', () async {
      var receivedArgs = <dynamic, dynamic>{};
      mockPlatformChannel(handler: (call) async {
        receivedArgs = Map.castFrom(call.arguments as Map);
      });

      await RecorderStream().initialize();
      expect(receivedArgs['sampleRate'], 16000);
      expect(receivedArgs['showLogs'], false);
    });

    test('initialize sends correct method call with custom args', () async {
      var receivedArgs = <dynamic, dynamic>{};
      mockPlatformChannel(handler: (call) async {
        receivedArgs = Map.castFrom(call.arguments as Map);
      });

      await RecorderStream().initialize(
        sampleRate: 24000,
        showLogs: true,
      );
      expect(receivedArgs['sampleRate'], 24000);
      expect(receivedArgs['showLogs'], true);
    });

    test('start sends startRecording method call', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'startRecording');
      });

      await RecorderStream().start();
    });

    test('stop sends stopRecording method call', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'stopRecording');
      });

      await RecorderStream().stop();
    });

    test('dispose is idempotent', () {
      mockPlatformChannel();
      final recorder = RecorderStream();
      recorder.dispose();
      expect(() => recorder.dispose(), returnsNormally);
    });
  });

  group('PlayerStream', () {
    test('initialize sends correct method call with defaults', () async {
      var receivedArgs = <dynamic, dynamic>{};
      mockPlatformChannel(handler: (call) async {
        receivedArgs = Map.castFrom(call.arguments as Map);
      });

      await PlayerStream().initialize();
      expect(receivedArgs['sampleRate'], 16000);
      expect(receivedArgs['showLogs'], false);
    });

    test('start sends startPlayer method call', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'startPlayer');
      });

      await PlayerStream().start();
    });

    test('stop sends stopPlayer method call', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'stopPlayer');
      });

      await PlayerStream().stop();
    });

    test('writeChunk sends data via method channel', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'writeChunk');
        expect(call.arguments['data'], isA<Uint8List>());
        expect((call.arguments['data'] as Uint8List).length, 4);
      });

      await PlayerStream().writeChunk(Uint8List.fromList([1, 2, 3, 4]));
    });

    test('usePhoneSpeaker sends correct method call', () async {
      mockPlatformChannel(handler: (call) async {
        expect(call.method, 'usePhoneSpeaker');
        expect(call.arguments['value'], true);
      });

      await PlayerStream().usePhoneSpeaker(true);
    });

    test('dispose is idempotent', () {
      mockPlatformChannel();
      final player = PlayerStream();
      player.dispose();
      expect(() => player.dispose(), returnsNormally);
    });
  });

  group('SoundStreamException', () {
    test('toString includes message', () {
      final ex = SoundStreamException('test error');
      expect(ex.toString(), contains('test error'));
    });

    test('toString includes cause when provided', () {
      final cause = PlatformException(code: 'test', message: 'cause');
      final ex = SoundStreamException('wrapper', cause);
      expect(ex.toString(), contains('cause'));
    });
  });

  group('Typed method calls', () {
    test('initializePlayer returns Future<void>', () async {
      mockPlatformChannel(handler: (call) async => true);
      expect(
        () async => await PlayerStream().initialize(),
        returnsNormally,
      );
    });

    test('startRecording returns Future<void>', () async {
      mockPlatformChannel(handler: (call) async => true);
      expect(
        () async => await RecorderStream().start(),
        returnsNormally,
      );
    });
  });
}
