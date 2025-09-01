import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../auth/auth_store.dart';
import 'tickets_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  late final ApiClient _api;
  late final AuthStore _auth;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthStore(_api);
    _auth.init(); // récupère le token s'il existe
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
        await _auth.login(_email.text.trim(), _password.text);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TicketsScreen(api: _api)));
        } catch (e) {
        final msg = e.toString();
        setState(() => _error = msg);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        } finally {
        if (mounted) setState(() => _loading = false);
        }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Connexion…' : 'Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
