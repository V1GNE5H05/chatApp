import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  final TextEditingController _nameController = TextEditingController(text: 'Your Name');
  final TextEditingController _bioController = TextEditingController(text: 'Your bio goes here');

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepOrange[300],
                  child: const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add your bio',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Switch
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              secondary: const Icon(Icons.brightness_6),
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
              activeColor: Colors.deepOrange,
            ),
          ),

          // Other Settings
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Notifications'),
                  trailing: Icon(Icons.chevron_right),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Privacy'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
