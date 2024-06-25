import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_sos/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'getlocation.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _contactController = TextEditingController();

  User? _user;
  String _emergencyPhone = '';

  bool isEmergencyContactSet = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        if (userDoc['emergencyPhone'] == '') {
          setState(() {
            isEmergencyContactSet = false;
          });
        } else {
          setState(() {
            _emergencyPhone = userDoc['emergencyPhone'];
            isEmergencyContactSet = true;
          });
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  Future<void> _saveData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'emergencyPhone': _contactController.text,
      });
      print("Data saved");
      await _fetchUserData();
    } else {
      print("No user signed in");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Savior'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings),
            )
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: isEmergencyContactSet
                ? Column(
                    children: [
                      /* Container(
              margin: EdgeInsets.all(15),
              child: FlatButton(
                child: Text(
                  'Message',
                  style: TextStyle(fontSize: 15.0),
                ),
                color: Colors.blueAccent,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Message()),
                  );
                },
              ),
            ),*/
                      Container(
                        margin: const EdgeInsets.all(15),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await FlutterPhoneDirectCaller.callNumber(
                                _emergencyPhone);
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call),
                              SizedBox(width: 10),
                              Text(
                                'Call',
                                style: TextStyle(fontSize: 15.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(15),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message),
                              SizedBox(width: 10),
                              Text(
                                'Get Location & Send Message',
                                style: TextStyle(fontSize: 15.0),
                              ),
                            ],
                          ),
                          // color: Colors.blueAccent,
                          // textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const GetLocation()),
                            );
                          },
                        ),
                      ),
                      /* Container(
                    margin: EdgeInsets.all(15),
                    child: FlatButton(
                      child: Text(
                        'Live Location Tracking',
                        style: TextStyle(fontSize: 15.0),
                      ),
                      color: Colors.blueAccent,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LiveLocationTracking()),
                        );
                      },
                    ),
                  ),*/

                      /*FloatingActionButton.extended(
              onPressed: () {},
              icon: Icon(Icons.save),
              label: Text("Notifications"),
            ),*/
                      /*FloatingActionButton(
                    child: Icon(Icons.notifications),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    onPressed: () => {},
                  ),*/
                    ],
                  )
                : Column(
                    children: [
                      const Text("Setup Emergency Contact Number"),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(
                            labelText: 'Emergency Contact Number'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty || value.toString().length < 11) {
                            return 'Number should be at least 11 characters long';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _saveData,
                        child: const Text('Setup'),
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
