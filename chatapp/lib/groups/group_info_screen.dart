import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class GroupInfoScreen extends StatefulWidget {
  final String groupId;

  const GroupInfoScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _bioController = TextEditingController();
  List<dynamic> members = [];
  String? groupProfileUrl;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  void _loadGroupData() async {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        members = data['members'] ?? [];
        _bioController.text = data['bio'] ?? '';
        groupProfileUrl = data['profileUrl'] ?? ''; // Assuming profile URL is stored in Firestore
      });
    }
  }

  // Function to convert image to base64
  Future<String> _convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);  // Return base64 string
  }

  // Function to update group profile image in Firestore
  void _updateGroupProfile(String base64Image) {
    FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'profileUrl': base64Image,
    }).then((value) {
      setState(() {
        groupProfileUrl = base64Image;  // Update UI after storing the base64
      });
    });
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imgFile = File(image.path);
      String base64String = await _convertImageToBase64(imgFile);
      _updateGroupProfile(base64String);
    }
  }

  void _updateBio() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .update({'bio': _bioController.text.trim()});
  }

  void _removeMember(String uid) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': FieldValue.arrayRemove([uid])
    });
    _loadGroupData();
  }

  void _addMember(String uid) async {
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
      'members': FieldValue.arrayUnion([uid])
    });
    _loadGroupData();
  }

  Future<String> _getUserName(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return snap.exists ? snap.data()!['name'] ?? 'Unknown' : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text("Group Info"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Circle Icon at Top Center
            CircleAvatar(
              radius: 50,
              backgroundImage: groupProfileUrl != null
                  ? MemoryImage(base64Decode(groupProfileUrl!))
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            SizedBox(height: 20),
            // Bio Section
            Text("Group Bio:", style: TextStyle(color: Colors.white70)),
            TextField(
              controller: _bioController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[850],
                hintText: "Enter group bio...",
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _updateBio(),
            ),
            SizedBox(height: 20),
            // Members Section
            Text("Members:", style: TextStyle(color: Colors.white70)),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final uid = members[index];
                  return FutureBuilder<String>(
                    future: _getUserName(uid),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? '...';
                      return ListTile(
                        title: Text(name, style: TextStyle(color: Colors.white)),
                        trailing: uid == currentUserUid
                            ? null
                            : IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.redAccent),
                                onPressed: () => _removeMember(uid),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: Text("Change Profile Image"),
                ),
                SizedBox(width: 20),  // Space between buttons
                ElevatedButton(
                  onPressed: _updateBio,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  child: Text("Save Changes"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
