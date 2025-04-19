import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String uid;
  late WebSocketChannel _channel;

  Function(String from, String message)? onMessageReceived;

  WebSocketService({required this.uid}) {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080'));
    _channel.sink.add(jsonEncode({'type': 'auth', 'uid': uid}));

    _channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'message' && onMessageReceived != null) {
        onMessageReceived!(data['from'], data['text']);
      }
    });
  }

  void sendMessage(String toUid, String message) {
    _channel.sink.add(jsonEncode({
      'type': 'message',
      'to': toUid,
      'text': message,
    }));
  }

  void dispose() {
    _channel.sink.close();
  }
}
