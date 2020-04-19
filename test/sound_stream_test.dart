import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:sound_stream/sound_stream.dart';

void main() {
  const MethodChannel channel = MethodChannel('sound_stream');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });
}
