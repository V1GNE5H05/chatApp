import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final List<String> _selectedUserIds = [];
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Group")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(labelText: "Group Name"),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("Select Users to Add"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isNotEqualTo: currentUserUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final uid = user['uid'];
                    final email = user['email'];

                    return CheckboxListTile(
                      title: Text(email),
                      value: _selectedUserIds.contains(uid),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedUserIds.add(uid);
                          } else {
                            _selectedUserIds.remove(uid);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _createGroup,
            child: const Text("Create Group"),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty || _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter group name and select users.")),
      );
      return;
    }

    final members = [..._selectedUserIds, currentUserUid]; // Add current user

    await FirebaseFirestore.instance.collection('groups').add({
      'name': groupName,
      'members': members,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }
}
