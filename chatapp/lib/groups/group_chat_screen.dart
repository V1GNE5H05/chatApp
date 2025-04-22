import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, String> _nameCache = {};

  // Fetch the sender's name
  Future<String> _getSenderName(String senderId) async {
    if (_nameCache.containsKey(senderId)) {
      return _nameCache[senderId]!;
    }

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users') // Assuming you have a 'users' collection
        .doc(senderId)
        .get();

    final userName = userSnapshot.exists ? userSnapshot.data()!['name'] : 'Unknown User';
    _nameCache[senderId] = userName;
    return userName;
  }

  // Send message
  void _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .add({
      'sender': currentUserUid,
      'text': text,
      'timestamp': Timestamp.now(),
    });

    _messageController.clear();
  }

  // Format time
  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  // Format date
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return DateFormat.yMMMMd().format(date);
    if (diff == 1) return "Yesterday";
    return DateFormat.yMMMMd().format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              child: Text("💀", style: TextStyle(fontSize: 20)),
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.groupName, style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Online", style: TextStyle(fontSize: 12)),
              ],
            ),
            Spacer(),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.ghost, color: Colors.deepOrange[100]),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;
                String? lastDateShown;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final senderId = msg['sender'];
                    final isMe = senderId == currentUserUid;
                    final text = msg['text'];
                    final time = _formatTime(msg['timestamp']);
                    final date = _formatDate(msg['timestamp']);

                    bool showDate = false;
                    if (lastDateShown != date) {
                      lastDateShown = date;
                      showDate = true;
                    }

                    return FutureBuilder<String>(
                      future: senderId == currentUserUid
                          ? Future.value("You")
                          : _getSenderName(senderId),
                      builder: (context, userSnapshot) {
                        final senderName = userSnapshot.data ?? '...';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDate)
                              Center(
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.brown[800],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(date,
                                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ),
                              ),
                            Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe)
                                    CircleAvatar(
                                      backgroundColor: Colors.deepOrange,
                                      child: Text("💀", style: TextStyle(fontSize: 16)),
                                      radius: 16,
                                    ),
                                  SizedBox(width: 6),
                                  Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.25),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isMe ? Colors.deepOrange : Colors.grey[800],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Sender's name
                                        Text(
                                          senderName, // Show sender's name
                                          style: TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                        SizedBox(height: 4),
                                        // Message text
                                        Text(
                                          text,
                                          style: TextStyle(color: Colors.white, fontSize: 15),
                                        ),
                                        SizedBox(height: 4),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            time,
                                            style: TextStyle(color: Colors.white60, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, color: Colors.white12),
          Container(
            color: Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.orange),
                SizedBox(width: 8),
                Text("💀", style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a dark whisper...',
                      hintStyle: TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black54,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: Colors.deepOrange,
                    child: Icon(Icons.send, color: Colors.white),
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
