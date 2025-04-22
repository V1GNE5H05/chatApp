import 'package:chatapp/chat_home.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/signup_screen.dart';
import 'package:chatapp/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Optional: Set persistence explicitly (useful for web)
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepOrange[800],
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepOrange),
          ),
        ),
      ),
      home: AuthGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
      },
    );
  }
}
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error occurred
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return ChatHomePage();
        }

        // Not logged in
        return WelcomeScreen();
      },
    );
  }
}
