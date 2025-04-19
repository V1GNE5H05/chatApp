import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  Map<String, dynamic>? _searchedUser;
  bool _isLoading = false;

  void _searchUser() async {
    setState(() {
      _isLoading = true;
      _searchedUser = null;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: _emailController.text.trim())
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userDoc = querySnapshot.docs.first;
      setState(() {
        _searchedUser = {'uid': userDoc.id, 'email': userDoc['email']};
      });
    } else {
      setState(() {
        _searchedUser = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user found with that email.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search User'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter user email',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : _searchedUser != null
                    ? ListTile(
                        title: Text(_searchedUser!['email']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                friendUid: _searchedUser!['uid'],
                                friendName: _searchedUser!['email'],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(),
          ],
        ),
      ),
    );
  }
}
