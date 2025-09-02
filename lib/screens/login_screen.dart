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

  // UI
  final Color _bg = const Color(0xFF0E0E0E);
  final Color _fg = const Color(0xFFEDEDED);
  final Color _muted = const Color(0xFF9E9E9E);
  final Color _accent = const Color(0xFFF39C12);

  int _tabIndex = 0; // 0 = Connexion

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _auth = AuthStore(_api);
  }

  Future<void> _submit() async {
    if (_tabIndex != 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketsScreen(api: _api)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(_error!),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputBorder underline(Color c) =>
        UnderlineInputBorder(borderSide: BorderSide(color: c, width: 1));

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding
              Text(
                'Cinéphoria',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _fg.withOpacity(.9),
                  letterSpacing: .2,
                ),
              ),

              const SizedBox(height: 48), // <-- plus grand espace

              // Onglet Connexion seul
              _TabLabel(
                label: 'CONNEXION',
                active: true,
                accent: _accent,
                fg: _fg,
                muted: _muted,
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // Email
              Text(
                'Email',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _muted,
                  letterSpacing: .2,
                ),
              ),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: _fg),
                cursorColor: _accent,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: underline(_fg.withOpacity(.18)),
                  focusedBorder: underline(_accent),
                ),
              ),
              const SizedBox(height: 28),

              // Mot de passe
              Text(
                'Mot de passe',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _muted,
                  letterSpacing: .2,
                ),
              ),
              TextField(
                controller: _password,
                obscureText: true,
                style: TextStyle(color: _fg),
                cursorColor: _accent,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  enabledBorder: underline(_fg.withOpacity(.18)),
                  focusedBorder: underline(_accent),
                ),
              ),

              const SizedBox(height: 36),

              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Colors.red[300])),
                const SizedBox(height: 8),
              ],

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
                  child: Text(_loading ? 'Connexion…' : 'Connexion'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.active,
    required this.onTap,
    required this.accent,
    required this.fg,
    required this.muted,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color accent;
  final Color fg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final color = active ? fg : muted.withOpacity(.7);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 3,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: active ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
