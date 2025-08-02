import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_sos/screens/auth/login_screen.dart';
import 'package:emergency_sos/screens/core/settings_screen.dart';
import 'package:emergency_sos/screens/emergency/emergency_contacts_screen.dart';
import 'package:emergency_sos/screens/emergency/emergency_history_screen.dart';
import 'package:emergency_sos/screens/emergency/emergency_activation_screen.dart';
import 'package:emergency_sos/widgets/sos_button.dart';
import 'package:emergency_sos/widgets/loading_widgets.dart';
import 'package:emergency_sos/widgets/error_widgets.dart';
import 'package:emergency_sos/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:emergency_sos/screens/location/getlocation.dart';
import 'package:emergency_sos/screens/location/nearby_services_screen.dart';
import 'package:emergency_sos/screens/location/route_to_safety_screen.dart';
import 'package:emergency_sos/screens/location/location_history_screen.dart';
import 'package:emergency_sos/screens/location/offline_maps_screen.dart';
import 'package:emergency_sos/screens/location/location_accuracy_screen.dart';
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
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      _user = _auth.currentUser;
      if (_user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          if (userDoc['emergencyPhone'] == '') {
            setState(() {
              isEmergencyContactSet = false;
              isLoading = false;
            });
          } else {
            setState(() {
              _emergencyPhone = userDoc['emergencyPhone'];
              isEmergencyContactSet = true;
              isLoading = false;
            });
          }
        } else {
          setState(() {
            isEmergencyContactSet = false;
            isLoading = false;
          });
        }
      } else {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Failed to load user data. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'emergencyPhone': _contactController.text,
        });
        ErrorWidgets.snackBarSuccess(
          context: context,
          message: 'Emergency contact saved successfully!',
        );
        await _fetchUserData();
      } else {
        ErrorWidgets.snackBarError(
          context: context,
          message: 'No user signed in',
        );
      }
    } catch (e) {
      ErrorWidgets.snackBarError(
        context: context,
        message: 'Failed to save emergency contact. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savior'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: LoadingWidgets.overlayLoading(
        isLoading: isLoading,
        message: 'Loading...',
        child: Container(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (hasError) {
      return ErrorWidgets.generalError(
        message: errorMessage,
        onRetry: _fetchUserData,
      );
    }

    if (isEmergencyContactSet) {
      return _buildEmergencyInterface();
    } else {
      return _buildSetupInterface();
    }
  }

  Widget _buildEmergencyInterface() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        SOSButton(
          onPressed: () {
            Navigator.pushNamed(context, EmergencyActivationScreen.routeName);
          },
          label: 'Tap for Emergency Activation',
        ),
        const SizedBox(height: 40),
        EmergencyActionButton(
          icon: Icons.people,
          label: 'Emergency Contacts',
          backgroundColor: AppTheme.infoBlue,
          onPressed: () {
            Navigator.pushNamed(context, EmergencyContactsScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.history,
          label: 'Emergency History',
          backgroundColor: AppTheme.accentOrange,
          onPressed: () {
            Navigator.pushNamed(context, EmergencyHistoryScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.location_on,
          label: 'Get Location & Send Message',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GetLocation()),
            );
          },
        ),
        EmergencyActionButton(
          icon: Icons.local_hospital,
          label: 'Nearby Emergency Services',
          backgroundColor: Colors.purple,
          onPressed: () {
            Navigator.pushNamed(context, NearbyServicesScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.directions,
          label: 'Route to Safety',
          backgroundColor: Colors.indigo,
          onPressed: () {
            Navigator.pushNamed(context, RouteToSafetyScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.history,
          label: 'Location History',
          backgroundColor: Colors.teal,
          onPressed: () {
            Navigator.pushNamed(context, LocationHistoryScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.map,
          label: 'Offline Maps',
          backgroundColor: Colors.brown,
          onPressed: () {
            Navigator.pushNamed(context, OfflineMapsScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.gps_fixed,
          label: 'Location Accuracy',
          backgroundColor: Colors.deepPurple,
          onPressed: () {
            Navigator.pushNamed(context, LocationAccuracyScreen.routeName);
          },
        ),
        EmergencyActionButton(
          icon: Icons.phone,
          label: 'Call Emergency Contact',
          backgroundColor: Colors.green,
          onPressed: () async {
            try {
              await FlutterPhoneDirectCaller.callNumber(_emergencyPhone);
            } catch (e) {
              ErrorWidgets.snackBarError(
                context: context,
                message: 'Failed to make call. Please try again.',
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildSetupInterface() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emergency,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Setup Emergency Contact',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Add an emergency contact number to get help quickly when needed.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveData,
                  child: const Text('Save Emergency Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
