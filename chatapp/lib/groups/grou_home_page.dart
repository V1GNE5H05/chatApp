import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_screen.dart';
import 'group_create_screen.dart';

class GroupHomePage extends StatelessWidget {
  const GroupHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserUid == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in", style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.black,
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .where('members', arrayContains: currentUserUid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No groups found.", style: TextStyle(color: Colors.white70)),
                );
              }

              docs.sort((a, b) {
                final aTime = a['createdAt'] as Timestamp?;
                final bTime = b['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final group = docs[index];
                  final groupName = group['name'] ?? 'Unnamed Group';
                  final groupId = group.id;

                  return Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.deepOrange,
                        child: Icon(Icons.group, color: Colors.white),
                      ),
                      title: Text(groupName, style: const TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupChatScreen(
                              groupId: groupId,
                              groupName: groupName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          // Darker orange-to-black gradient overlay
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.deepOrange.shade900,
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Floating action button with padding
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0, right: 8.0),
        child: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupCreateScreen()),
            );
          },
          child: const Icon(Icons.group_add, color: Colors.white),
        ),
      ),
    );
  }
}
