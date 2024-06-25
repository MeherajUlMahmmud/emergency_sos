import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_sos/screens/home_screen.dart';
import 'package:emergency_sos/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  static const routeName = '/sign-up';

  const SignUpScreen({super.key});
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String error = '';

  Future<void> _register() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      print("User registered: ${userCredential.user}");

      _saveData();

      if (!context.mounted) return;
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
        error = "Something went wrong. Please try again later.";
      });
    }
  }

  Future<void> _saveData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'emergencyPhone': '',
      });
      print("Data saved");
    } else {
      print("No user signed in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        actions: [
          TextButton(
            child: const Text('Login'),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.limeAccent,
                  Colors.redAccent,
                ],
              ),
            ),
          ),
          Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty || value.toString().length < 3) {
                              return 'Name should be at least 3 characters long';
                            }
                            return null;
                          },
                        ),

                        // E-mail
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty || !value.contains('@')) {
                              return 'Invalid email';
                            }
                            return null;
                          },
                        ),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty || value.length <= 5) {
                              return 'Password should be at least 5 characters long';
                            }
                            return null;
                          },
                        ),

                        // Confirm Password
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                          ),
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty ||
                                value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _register,
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Sign Up'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
