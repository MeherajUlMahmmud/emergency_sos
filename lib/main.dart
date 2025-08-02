import 'package:emergency_sos/firebase_options.dart';
import 'package:emergency_sos/screens/auth/splash_screen.dart';
import 'package:emergency_sos/theme/app_theme.dart';
import 'package:emergency_sos/providers/theme_provider.dart';
import 'package:emergency_sos/providers/emergency_provider.dart';
import 'package:emergency_sos/core/di/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/core/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/core/settings_screen.dart';
import 'screens/emergency/emergency_contacts_screen.dart';
import 'screens/emergency/emergency_history_screen.dart';
import 'screens/emergency/emergency_activation_screen.dart';
import 'screens/location/nearby_services_screen.dart';
import 'screens/location/route_to_safety_screen.dart';
import 'screens/location/location_history_screen.dart';
import 'screens/location/offline_maps_screen.dart';
import 'screens/location/location_accuracy_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init(); // Initialize dependency injection
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => di.sl<ThemeProvider>(),
        ),
        ChangeNotifierProvider<EmergencyProvider>(
          create: (_) => di.sl<EmergencyProvider>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Savior',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScaleFactor),
                ),
                child: child!,
              );
            },
            home: const SplashScreen(),
            routes: {
              LoginScreen.routeName: (ctx) => const LoginScreen(),
              HomeScreen.routeName: (ctx) => const HomeScreen(),
              SettingsScreen.routeName: (ctx) => const SettingsScreen(),
              EmergencyContactsScreen.routeName: (ctx) =>
                  const EmergencyContactsScreen(),
              EmergencyHistoryScreen.routeName: (ctx) =>
                  const EmergencyHistoryScreen(),
              EmergencyActivationScreen.routeName: (ctx) =>
                  const EmergencyActivationScreen(),
              NearbyServicesScreen.routeName: (ctx) =>
                  const NearbyServicesScreen(),
              RouteToSafetyScreen.routeName: (ctx) =>
                  const RouteToSafetyScreen(),
              LocationHistoryScreen.routeName: (ctx) =>
                  const LocationHistoryScreen(),
              OfflineMapsScreen.routeName: (ctx) => const OfflineMapsScreen(),
              LocationAccuracyScreen.routeName: (ctx) =>
                  const LocationAccuracyScreen(),
            },
          );
        },
      ),
    );
  }
}
