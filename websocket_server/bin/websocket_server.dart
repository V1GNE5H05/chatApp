import 'dart:io';
import 'dart:convert';

final connectedClients = <String, WebSocket>{};

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('✅ WebSocket Server running on ws://${server.address.address}:${server.port}');

  await for (HttpRequest request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocket socket = await WebSocketTransformer.upgrade(request);
      handleConnection(socket);
    } else {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
    }
  }
}

void handleConnection(WebSocket socket) {
  String? uid;

  socket.listen(
    (message) {
      try {
        final data = jsonDecode(message);

        if (data['type'] == 'auth') {
          final receivedUid = data['uid'];
          if (receivedUid is String && receivedUid.isNotEmpty) {
            uid = receivedUid;
            connectedClients[uid!] = socket;
            print('🔗 $uid connected');
          } else {
            socket.add(jsonEncode({'error': 'Invalid or missing uid'}));
          }
        } else if (data['type'] == 'message') {
          final to = data['to'];
          final text = data['text'];
          if (to is String && to.isNotEmpty && text is String) {
            print('📤 $uid sent message to $to: $text');
            if (connectedClients.containsKey(to)) {
              connectedClients[to]!.add(jsonEncode({
                'type': 'message',
                'from': uid,
                'text': text,
                'timestamp': DateTime.now().toIso8601String(),
              }));
              print('✅ Delivered to $to');
            } else {
              print('❌ $to is not connected');
            }
          } else {
            socket.add(jsonEncode({'error': 'Invalid message format'}));
          }
        }
      } catch (e) {
        print('⚠️ Error: $e');
        socket.add(jsonEncode({'error': 'Invalid JSON format'}));
      }
    },
    onDone: () {
      if (uid != null) {
        connectedClients.remove(uid);
        print('🔌 $uid disconnected');
      }
    },
    onError: (e) => print('⚠️ Error: $e'),
  );
}