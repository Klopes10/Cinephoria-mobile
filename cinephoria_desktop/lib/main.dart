import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const CinephoriaDesktop());
}

class CinephoriaDesktop extends StatelessWidget {
  const CinephoriaDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiClient();
    return MaterialApp(
      title: 'Cinéphoria Desktop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: LoginScreen(api: api),
    );
  }
}
