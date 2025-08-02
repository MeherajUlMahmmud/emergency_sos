import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_sos/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_sms/flutter_sms.dart';

class GetLocation extends StatefulWidget {
  const GetLocation({super.key});

  @override
  Location createState() => Location();
}

class Location extends State<GetLocation> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _emergencyPhone = '';

  var locationMessage = "";
  bool isLoading = true;
  bool isDisabled = false;

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _emergencyPhone = userDoc['emergencyPhone'];
        });
      }
    } else {
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  void getCurrentLocation() async {
    LocationPermission permission;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      setState(() {
        isLoading = false;
        isDisabled = true;
      });
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try to ask for permissions again
        print('Location permissions are denied');
        setState(() {
          isLoading = false;
          isDisabled = true;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      print(
          'Location permissions are permanently denied, we cannot request permissions.');
      setState(() {
        isLoading = false;
        isDisabled = true;
      });
      return;
    }

    // When we reach here, permissions are granted and we can fetch the location
    var position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    var lastPosition = await Geolocator.getLastKnownPosition();
    print(lastPosition);
    var lat = position.latitude;
    var long = position.longitude;
    print("$lat , $long");

    setState(() {
      locationMessage = "Latitude : $lat , Longitude : $long";
      isLoading = false;
    });
  }

  @override
  void initState() {
    _fetchUserData();
    getCurrentLocation();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savior - Get Location & Message'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              size: 46.0,
              color: Colors.blue,
            ),
            const SizedBox(
              height: 10.0,
            ),
            const Text(
              "User Location",
              style: TextStyle(
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text("Position : $locationMessage"),
            TextButton(
              onPressed: () {
                getCurrentLocation();
              },
              child: const Text(
                "Get Current Location",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              child: ElevatedButton(
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Message',
                        style: TextStyle(fontSize: 15.0),
                      ),
                onPressed: () {
                  if (isDisabled == false) {
                    _sendSMS(
                      "Please Help me! My Current Location: $locationMessage",
                      _emergencyPhone,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is not enabled.'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _sendSMS(String message, String phoneNumber) async {
  String uri = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
  final Uri smsUri = Uri.parse(uri);
  if (await canLaunchUrl(smsUri)) {
    await launchUrl(smsUri);
  } else {
    throw 'Could not launch $uri';
  }
}
