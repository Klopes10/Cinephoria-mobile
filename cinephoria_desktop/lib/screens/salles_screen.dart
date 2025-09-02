import 'package:flutter/material.dart';
import '../api/api_client.dart';

class SallesScreen extends StatelessWidget {
  const SallesScreen({super.key, required this.api});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salles')),
      body: const Center(child: Text('Bienvenue (connexion OK)')),
    );
  }
}
