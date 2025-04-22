import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String friendUid;
  final String friendName;

  const ChatScreen({
    Key? key,
    required this.friendUid,
    required this.friendName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late WebSocketChannel _webSocketChannel;
  final String serverUrl = 'ws://192.168.158.144:8080';
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    _webSocketChannel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _webSocketChannel.sink.add(jsonEncode({
      'type': 'auth',
      'uid': currentUserUid,
    }));
    _webSocketChannel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'message') {
        _storeMessageInFirestore(
          sender: data['sender'],
          receiver: data['receiver'],
          text: data['text'],
          timestamp: data['timestamp'],
          isImage: data['isImage'] ?? false,
        );
         _updateFriendsCollection(data['sender'], data['receiver']);
      }
    });
  }

  void _sendMessage(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final messageData = {
      'type': 'message',
      'sender': currentUserUid,
      'receiver': widget.friendUid,
      'text': message,
      'timestamp': timestamp,
    };
    _webSocketChannel.sink.add(jsonEncode(messageData));
    _storeMessageInFirestore(
      sender: currentUserUid,
      receiver: widget.friendUid,
      text: message,
      timestamp: timestamp,
    );
    _updateFriendsCollection(currentUserUid, widget.friendUid);

  }

  void _storeMessageInFirestore({
    required String sender,
    required String receiver,
    required String text,
    required String timestamp,
    bool isImage = false,
  }) {
    FirebaseFirestore.instance.collection('messages').add({
      'sender': sender,
      'receiver': receiver,
      'text': text,
      'timestamp': Timestamp.fromDate(DateTime.parse(timestamp)),
      'participants': [sender, receiver],
      'isImage': isImage,
    });
  }
  Future<void> _updateFriendsCollection(String senderUid, String receiverUid) async {
  final firestore = FirebaseFirestore.instance;

  // Update sender's friends list
  final senderRef = firestore.collection('friends').doc(senderUid);
  await senderRef.set({
    'uids': FieldValue.arrayUnion([receiverUid])
  }, SetOptions(merge: true));

  // Update receiver's friends list
  final receiverRef = firestore.collection('friends').doc(receiverUid);
  await receiverRef.set({
    'uids': FieldValue.arrayUnion([senderUid])
  }, SetOptions(merge: true));
}

  @override
  void dispose() {
    _messageController.dispose();
    _webSocketChannel.sink.close();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('h:mm a').format(dateTime);
  }

  String _formatDateLabel(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('MMMM dd, yyyy').format(date);
  }
  Future<void> _pickAndSendImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final timestamp = DateTime.now().toIso8601String();
    final messageData = {
      'type': 'message',
      'sender': currentUserUid,
      'receiver': widget.friendUid,
      'text': base64Image,
      'isImage': true,
      'timestamp': timestamp,
    };

    _webSocketChannel.sink.add(jsonEncode(messageData));

    _storeMessageInFirestore(
      sender: currentUserUid,
      receiver: widget.friendUid,
      text: base64Image,
      timestamp: timestamp,
      isImage: true,
    );
  }
}

  Widget _buildMessageList() {
    final sentMessagesQuery = FirebaseFirestore.instance
        .collection('messages')
        .where('sender', isEqualTo: currentUserUid)
        .where('receiver', isEqualTo: widget.friendUid);

    final receivedMessagesQuery = FirebaseFirestore.instance
        .collection('messages')
        .where('sender', isEqualTo: widget.friendUid)
        .where('receiver', isEqualTo: currentUserUid);

    return StreamBuilder<QuerySnapshot>(
      stream: sentMessagesQuery.snapshots(),
      builder: (context, sentSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: receivedMessagesQuery.snapshots(),
          builder: (context, receivedSnapshot) {
            if (sentSnapshot.connectionState == ConnectionState.waiting ||
                receivedSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final allMessages = [
              ...?sentSnapshot.data?.docs,
              ...?receivedSnapshot.data?.docs,
            ];

            allMessages.sort((a, b) {
              return a['timestamp'].compareTo(b['timestamp']);
            });

            Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};

            for (var msg in allMessages) {
              String dateLabel = _formatDateLabel(msg['timestamp']);
              if (!groupedMessages.containsKey(dateLabel)) {
                groupedMessages[dateLabel] = [];
              }
              groupedMessages[dateLabel]!.add(msg);
            }

            final dateKeys = groupedMessages.keys.toList();

            return ListView.builder(
              padding: EdgeInsets.all(8),
              reverse: false,
              itemCount: dateKeys.length,
              itemBuilder: (context, dateIndex) {
                String date = dateKeys[dateIndex];
                List<QueryDocumentSnapshot> messages = groupedMessages[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 12),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(color: Colors.deepOrange[200]),
                        ),
                      ),
                    ),
                    ...messages.map((message) {
                      final isMe = message['sender'] == currentUserUid;
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CircleAvatar(
                                  backgroundColor: Colors.deepOrange[800],
                                  child: FaIcon(
                                    FontAwesomeIcons.skull,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                              ),
                            Flexible(
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 12),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.deepOrange[700]
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    message['isImage'] == true
                                    ? Image.memory(
                                      base64Decode(message['text']),
                                      width: 200,
                                    )
                                    : Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: isMe ? Colors.black : Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(message['timestamp']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe
                                            ? Colors.black.withOpacity(0.6)
                                            : Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange[900],
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepOrange[700],
              child: FaIcon(FontAwesomeIcons.skull, color: Colors.black, size: 16),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName, style: TextStyle(color: Colors.white)),
                Text("Online",
                    style: TextStyle(
                      color: Colors.deepOrange[200],
                      fontSize: 12,
                    )),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.ghost, color: Colors.deepOrange[100]),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: Colors.deepOrange[100]),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.deepOrange.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.image, color: Colors.deepOrange[300]),
                  onPressed: _pickAndSendImage,
                ),

                IconButton(
                  icon: FaIcon(FontAwesomeIcons.microphone, color: Colors.deepOrange[300]),
                  onPressed: () {},
                ),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.skull, color: Colors.deepOrange[300]),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a dark whisper...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange, Colors.deepOrange[800]!],
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        _sendMessage(_messageController.text);
                        _messageController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
