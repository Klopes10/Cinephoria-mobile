import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'auth/auth_store.dart';
import 'screens/login_screen.dart';
import 'screens/tickets_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const CinephoriaApp());
}

class CinephoriaApp extends StatelessWidget {
  const CinephoriaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cinéphoria Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const BootScreen(),
    );
  }
}

class BootScreen extends StatefulWidget {
  const BootScreen({super.key});
  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  final _api = ApiClient();
  late final AuthStore _auth = AuthStore(_api);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _auth.init();
    if (!mounted) return;
    try {
      await _api.fetchMyUpcomingTickets();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketsScreen(api: _api)),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(api: _api)), // <-- FIX
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
