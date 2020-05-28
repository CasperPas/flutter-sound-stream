import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

const _PORT = 8888;

main() {
  final connections = Set<WebSocket>();
  HttpServer.bind('localhost', _PORT).then((HttpServer server) {
    print('[+]WebSocket listening at -- ws://localhost:$_PORT/');
    server.listen((HttpRequest request) {
      WebSocketTransformer.upgrade(request).then((WebSocket ws) {
        connections.add(ws);
        ws.listen(
          (data) {
            // Broadcast data to all other clients
            for (var conn in connections) {
              if (conn != ws && conn.readyState == WebSocket.open) {
                conn.add(data);
              }
            }
          },
          onDone: () {
            connections.remove(ws);
            print('[+]Done :)');
          },
          onError: (err) {
            connections.remove(ws);
            print('[!]Error -- ${err.toString()}');
          },
          cancelOnError: true,
        );
      }, onError: (err) => print('[!]Error -- ${err.toString()}'));
    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
