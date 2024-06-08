import 'dart:convert';
import 'dart:io';
import 'dart:async' show Timer;

import 'dart:typed_data';

const _PORT = 8888;
const _RECORDER_BPP = 16;
const _sampleRate = 16000;

void writeWaveFileHeader(File out, int totalAudioLen, int longSampleRate,
    int channels, int byteRate) {
  final totalDataLen = totalAudioLen + 36;
  Uint8List header = Uint8List.fromList([
    ...utf8.encode('RIFF'),
    (totalDataLen & 0xff),
    ((totalDataLen >> 8) & 0xff),
    ((totalDataLen >> 16) & 0xff),
    ((totalDataLen >> 24) & 0xff),
    ...utf8.encode('WAVEfmt '),
    16, // 4 bytes: size of 'fmt ' chunk
    0,
    0,
    0,
    1, // format = 1
    0,
    channels,
    0,
    (longSampleRate & 0xff),
    ((longSampleRate >> 8) & 0xff),
    ((longSampleRate >> 16) & 0xff),
    ((longSampleRate >> 24) & 0xff),
    (byteRate & 0xff),
    ((byteRate >> 8) & 0xff),
    ((byteRate >> 16) & 0xff),
    ((byteRate >> 24) & 0xff),
    (1), // block align
    0,
    _RECORDER_BPP,
    0,
    ...utf8.encode('data'),
    (totalAudioLen & 0xff),
    ((totalAudioLen >> 8) & 0xff),
    ((totalAudioLen >> 16) & 0xff),
    ((totalAudioLen >> 24) & 0xff),
  ]);

  out.writeAsBytesSync(header);
}

main() {
  Timer? timer;
  File? file, tmp;
  int dataSize = 0;
  WebSocket.connect('ws://localhost:$_PORT').then((WebSocket ws) {
    if (ws.readyState == WebSocket.open) {
      ws.listen(
        (data) {
          if (timer == null) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = '$timestamp.wav';
            file = File(fileName);
            tmp = File('$fileName.tmp');
            file!.openWrite();
            tmp!.openWrite();
            dataSize = 0;
            timer = Timer(const Duration(seconds: 5), () {
              print('Timeout!');
              writeWaveFileHeader(file!, dataSize, _sampleRate, 1,
                  _RECORDER_BPP * _sampleRate ~/ 8);
              file!.writeAsBytesSync(tmp!.readAsBytesSync(),
                  flush: true, mode: FileMode.append);
              tmp!.deleteSync();
              tmp = null;
              file = null;
              timer = null;
            });
          }
          final Uint8List buff = data;
          dataSize += buff.lengthInBytes;
          print(dataSize);
          tmp?.writeAsBytesSync(buff, flush: true, mode: FileMode.append);
        },
        onDone: () => print('[+]Done :)'),
        onError: (err) => print('[!]Error -- ${err.toString()}'),
        cancelOnError: true,
      );
    } else
      print('[!]Connection Denied');
    // in case, if serer is not running now
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
