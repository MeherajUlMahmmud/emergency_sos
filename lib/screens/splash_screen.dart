import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_sos/screens/home_screen.dart';
import 'package:emergency_sos/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void checkUser() async {
    final User? _user = _auth.currentUser;

    if (_user == null) {
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
    } else {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        });
      } else {
        // logout user
        await _auth.signOut();
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, LoginScreen.routeName);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Savior",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
