import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';
import 'models/authentication.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Authentication(),
        )
      ],
      child: MaterialApp(
        title: 'Savior',
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home: const LoginScreen(),
        routes: {
          SignUpScreen.routeName: (ctx) => const SignUpScreen(),
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
        },
      ),
    );
  }
}
