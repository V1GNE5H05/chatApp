import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Uint8List? _imageBytes;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile =
          await _firestore.collection('users').doc(user.uid).get();
      if (userProfile.exists) {
        setState(() {
          _usernameController.text = userProfile['username'] ?? '';
          _bioController.text = userProfile['bio'] ?? '';
          String? imageBase64 = userProfile['profileImage'];
          if (imageBase64 != null && imageBase64.isNotEmpty) {
            _imageBytes = Uint8List.fromList(base64Decode(imageBase64));
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // Compress image
      maxWidth: 600,
      maxHeight: 600,
    );
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  Future<void> _saveProfileData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String base64Image = '';
      if (_imageBytes != null) {
        final encoded = base64Encode(_imageBytes!);
        if (encoded.length < 990000) {
          base64Image = encoded;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image too large. Please pick a smaller image.')),
          );
          return;
        }
      }

      await _firestore.collection('users').doc(user.uid).set({
        'username': _usernameController.text,
        'bio': _bioController.text,
        'profileImage': base64Image,
      }, SetOptions(merge: true));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.deepOrangeAccent,
                  backgroundImage:
                      _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                  child: _imageBytes == null
                      ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.info_outline, color: Colors.white),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await _saveProfileData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Saved')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
