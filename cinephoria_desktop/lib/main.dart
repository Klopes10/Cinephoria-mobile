import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Crée une seule instance d'API pour toute l'app
  final api = ApiClient(); // Ajoute baseUrl/token si nécessaire
  runApp(CinephoriaApp(api: api));
}

class CinephoriaApp extends StatelessWidget {
  final ApiClient api;
  const CinephoriaApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinéphoria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      // Écran d’accueil : Login (qui recevra l’ApiClient)
      home: LoginScreen(api: api),
    );
  }
}
