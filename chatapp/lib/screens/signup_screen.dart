import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          // Store user details in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'uid': user.uid,
            'createdAt': Timestamp.now(),
          });

          // Create an entry in the 'friends' collection
          await FirebaseFirestore.instance.collection('friends').doc(user.uid).set({
            'uid': user.uid,
            'friends': [], // Initialize with an empty list of friends
          });

          Navigator.pop(context); // Navigate back to login screen
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Registration failed. Please try again';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepOrange[50],
      appBar: AppBar(
        title: Text("Sign Up", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepOrange[800],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Enter your name' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => 
                  value!.isEmpty ? 'Enter your email' : (!value.contains('@') ? 'Enter a valid email' : null),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => 
                  value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Confirm your password' : null,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange[800]),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Already have an account? Sign in", style: TextStyle(color: Colors.deepOrange[800])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
