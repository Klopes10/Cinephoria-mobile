import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../auth/auth_store.dart';
// ❌ import 'salles_screen.dart';  // SUPPRIMER
import 'tickets_screen.dart';        // ✅ utiliser TicketsScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // DA
  final _bg     = const Color(0xFF0E0E0E);
  final _fg     = const Color(0xFFEDEDED);
  final _muted  = const Color(0xFF9E9E9E);
  final _accent = const Color(0xFFF39C12);

  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  late final AuthStore _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthStore(widget.api);
  }

  InputDecoration _decoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _fg.withOpacity(.18)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _accent, width: 1.2),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketsScreen(api: widget.api)), // ✅ go tickets
      );
    } catch (e) {
      setState(() => _error = e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF2A2A2A),
          content: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding
              Text(
                'Cinéphoria',
                style: TextStyle(
                  color: _fg.withOpacity(.92),
                  fontSize: 20,
                  letterSpacing: .2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),

              // Section titre
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 3,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'CONNEXION',
                    style: TextStyle(
                      color: _fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Email
              Text('Email',
                  style: TextStyle(color: _muted, letterSpacing: .2)),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: _fg),
                cursorColor: _accent,
                decoration: _decoration(),
              ),
              const SizedBox(height: 28),

              // Mot de passe
              Text('Mot de passe',
                  style: TextStyle(color: _muted, letterSpacing: .2)),
              TextField(
                controller: _password,
                obscureText: true,
                style: TextStyle(color: _fg),
                cursorColor: _accent,
                decoration: _decoration(),
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 20),
              ],

              // Bouton
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: _accent.withOpacity(.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      letterSpacing: .2,
                    ),
                  ),
                  child: Text(_loading ? 'Connexion…' : 'Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
