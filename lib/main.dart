import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const CinephoriaApp());

class CinephoriaApp extends StatelessWidget {
  const CinephoriaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinéphoria Mobile',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cinéphoria Mobile')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
          child: const Text('Commencer'),
        ),
      ),
    );
  }
}
