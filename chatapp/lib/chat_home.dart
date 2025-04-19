import 'dart:convert';
import 'package:chatapp/game/brick/brickmain.dart';
import 'package:chatapp/page/settings_page.dart';
import 'package:chatapp/screens/chat_screen.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/search_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({Key? key}) : super(key: key);

  @override
  _ChatHomePageState createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Chats', 'Groups', 'Mini Games'];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = false;
  String _searchQuery = "";
  late WebSocketChannel _webSocketChannel;
  final String serverUrl = 'ws://192.168.158.144:8080';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _connectWebSocket();
  }

  void _connectWebSocket() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _webSocketChannel = WebSocketChannel.connect(Uri.parse(serverUrl));
    _webSocketChannel.sink.add(jsonEncode({'type': 'auth', 'uid': uid}));
    _webSocketChannel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'message') {
        // Handle incoming messages if needed
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _webSocketChannel.sink.close();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.deepOrange[200]),
        decoration: InputDecoration(
          hintText: 'Search victims...',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.deepOrange),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: FaIcon(FontAwesomeIcons.times, size: 16),
                  color: Colors.deepOrange,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.trim()),
      ),
    );
  }

 Widget _buildUserList() {
  final myUid = FirebaseAuth.instance.currentUser!.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _buildEmptyState(FontAwesomeIcons.userSlash, 'No souls found');
      }

      // Get the list of users the current user has messaged
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friends')
            .doc(myUid)
            .snapshots(),
        builder: (context, friendsSnapshot) {
          if (!friendsSnapshot.hasData || !friendsSnapshot.data!.exists) {
            return _buildEmptyState(FontAwesomeIcons.search, 'No matching spirits');
          }

          List<dynamic> friendsList = friendsSnapshot.data!['friends'] ?? [];
          
          // Filter the users based on the friends list
          final allUsers = snapshot.data!.docs
              .where((doc) => doc['uid'] != myUid && friendsList.contains(doc['uid']))
              .toList();

          final filteredUsers = allUsers.where((doc) {
            final name = doc['name'].toString().toLowerCase();
            return _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
          }).toList();

          if (filteredUsers.isEmpty) {
            return _buildEmptyState(FontAwesomeIcons.search, 'No matching spirits');
          }

          return ListView.separated(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredUsers.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.deepOrange.withOpacity(0.1),
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildUserTile(user);
            },
          );
        },
      );
    },
  );
}
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: Colors.deepOrange[300], size: 40),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.deepOrange[200],
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.black,
          child: Text(
            user['name'][0].toUpperCase(),
            style: TextStyle(
              color: Colors.deepOrange[200],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user['name'],
          style: TextStyle(
            color: Colors.deepOrange[100],
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user['email'],
          style: TextStyle(color: Colors.grey[500]),
        ),
        trailing: FaIcon(
          FontAwesomeIcons.arrowRight,
          color: Colors.deepOrange,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                friendUid: user['uid'],
                friendName: user['name'],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.usersSlash,
            color: Colors.deepOrange.withOpacity(0.5),
            size: 50,
          ),
          SizedBox(height: 20),
          Text(
            'NO CULTS YET',
            style: TextStyle(
              color: Colors.deepOrange[200],
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          Text(
            'Gather your followers...',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'GET-TOGETHER',
          style: TextStyle(
            color: Colors.deepOrange[200],
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.deepOrange.withOpacity(0.5),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.deepOrange),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.skull, color: Colors.deepOrange),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.deepOrange),
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text('Settings', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.deepOrange),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrange,
          indicatorWeight: 4,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [
              Shadow(
                color: Colors.deepOrange.withOpacity(0.3),
                blurRadius: 4,
              ),
            ],
          ),
          tabs: _tabs.map((tab) => Tab(text: tab.toUpperCase())).toList(),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.black,
              Colors.deepOrange[900]!.withOpacity(0.35),
            ],
            stops: [0.0, 0.65, 1.0],
          ),
        ),
        child: Column(
          children: [
            if (_showSearchBar) _buildSearchBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(),
                  _buildGroupsTab(),
                  const Games(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'add_user',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchUserScreen()),
                    );
                  },
                  child: FaIcon(FontAwesomeIcons.userPlus, size: 20),
                  backgroundColor: Colors.deepOrange[800],
                ),
                SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'hand_button',
                  onPressed: () {
                    setState(() => _showSearchBar = !_showSearchBar);
                  },
                  child: FaIcon(FontAwesomeIcons.handSparkles, size: 24),
                  backgroundColor: Colors.deepOrange,
                ),
              ],
            )
          : null,
    );
  }
}

class Games extends StatelessWidget {
  const Games({super.key});
  @override
  Widget build(BuildContext context) => GameApp();
}
