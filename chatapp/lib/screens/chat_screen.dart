import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String serverUrl = 'ws://192.168.158.144:8080';
  late WebSocketChannel _webSocketChannel;
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  
  // Animation controllers
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  late Animation<double> _micButtonOpacity;
  late Animation<double> _sendButtonOpacity;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _setupAnimations();
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _sendButtonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: Curves.easeInOutBack,
      ),
    );

    _micButtonOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: Curves.easeIn,
      ),
    );

    _sendButtonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sendButtonController,
        curve: Curves.easeOut,
      ),
    );

    _messageController.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    if (_messageController.text.trim().isNotEmpty) {
      _sendButtonController.forward();
    } else {
      _sendButtonController.reverse();
    }
  }

  void _connectWebSocket() {
    _webSocketChannel = WebSocketChannel.connect(Uri.parse(serverUrl));

    _webSocketChannel.sink.add(jsonEncode({
      'type': 'auth',
      'uid': currentUserUid,
    }));

    _webSocketChannel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['type'] == 'message' &&
            data['receiver'] == currentUserUid &&
            data['sender'] == widget.friendUid) {
          _storeMessageInFirestore(
            sender: data['sender'],
            receiver: data['receiver'],
            text: data['text'],
            timestamp: DateTime.now().toIso8601String(),
          );
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        Future.delayed(Duration(seconds: 2), _connectWebSocket);
      },
      onDone: () {
        print('WebSocket closed');
        Future.delayed(Duration(seconds: 2), _connectWebSocket);
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();
    final messageData = {
      'type': 'message',
      'sender': currentUserUid,
      'receiver': widget.friendUid,
      'text': text,
      'timestamp': timestamp,
    };

    _webSocketChannel.sink.add(jsonEncode(messageData));
    _storeMessageInFirestore(
      sender: currentUserUid,
      receiver: widget.friendUid,
      text: text,
      timestamp: timestamp,
    );
    _messageController.clear();
  }

  Future<void> _storeMessageInFirestore({
    required String sender,
    required String receiver,
    required String text,
    required String timestamp,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('messages').add({
        'sender': sender,
        'receiver': receiver,
        'text': text,
        'timestamp': Timestamp.fromDate(DateTime.parse(timestamp)),
        'participants': FieldValue.arrayUnion([sender, receiver]),
      });
    } catch (e) {
      print('Error storing message: $e');
    }
  }

  Stream<QuerySnapshot> _getMessageStream() {
    return FirebaseFirestore.instance
        .collection('messages')
        .where('participants', arrayContains: currentUserUid)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    _webSocketChannel.sink.close();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Colors.deepOrange[900],
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.deepOrange[700],
              child: Icon(Icons.person, color: Colors.black),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName, style: TextStyle(color: Colors.white)),
                Text("Online", style: TextStyle(color: Colors.deepOrange[200], fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.cloudArrowUp, color: Colors.deepOrange[100]),
            onPressed: () {},
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.deepOrange[100]),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text("Clear chat", style: TextStyle(color: Colors.black87)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getMessageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.commentSlash, 
                            color: Colors.deepOrange[300], size: 40),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.deepOrange[200],
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['sender'] == currentUserUid && data['receiver'] == widget.friendUid) ||
                         (data['sender'] == widget.friendUid && data['receiver'] == currentUserUid);
                }).toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages with this user',
                      style: TextStyle(color: Colors.deepOrange[200]),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                String? lastDate;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final data = msg.data() as Map<String, dynamic>;
                    final isMe = data['sender'] == currentUserUid;
                    final time = DateFormat('h:mm a').format((data['timestamp'] as Timestamp).toDate());
                    final currentDate = _formatDate((data['timestamp'] as Timestamp).toDate());
                    final showDate = currentDate != lastDate;
                    lastDate = currentDate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                currentDate,
                                style: TextStyle(color: Colors.deepOrange[200], fontSize: 12),
                              ),
                            ),
                          ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.deepOrange[800] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['text'],
                                  style: TextStyle(
                                    color: isMe ? Colors.black : Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: isMe ? Colors.black54 : Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(
                  color: Colors.deepOrange.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Colors.deepOrange[300]),
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
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _sendButtonController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _sendButtonScale.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepOrange,
                              Colors.deepOrange[800]!,
                            ],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: _micButtonOpacity.value,
                              child: IconButton(
                                icon: Icon(Icons.mic, color: Colors.white),
                                onPressed: () {},
                              ),
                            ),
                            Opacity(
                              opacity: _sendButtonOpacity.value,
                              child: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}