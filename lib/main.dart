import 'package:flutter/material.dart';
import 'pages/onboarding_screen.dart';
import 'screens/home_screen.dart'; // 👈 Import your home page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafeMed',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/home': (context) => HomeScreen(), // 👈 Now registered
      },
    );
  }
}
