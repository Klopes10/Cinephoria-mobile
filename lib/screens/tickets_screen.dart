import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../auth/auth_store.dart';
import 'login_screen.dart';
import 'qrcode_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  late AuthStore _auth; // utilise le même ApiClient que l'app

  @override
  void initState() {
    super.initState();
    _auth = AuthStore(widget.api);
    _load();
  }

  void _load() {
    _future = widget.api.fetchMyUpcomingTickets();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _future;
  }

  Future<void> _forceLogin([String? message]) async {
    // optionnel : vider le token
    await _auth.logout();
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() => _forceLogin("Déconnecté.");

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEE d MMM HH:mm', 'fr_FR'); // nécessite initializeDateFormatting('fr_FR')

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes billets'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            final msg = snap.error.toString();
            // gestion expiration de session
            if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
              // retour automatique au login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forceLogin("Session expirée. Merci de vous reconnecter.");
              });
              return const Center(child: Text('Session expirée…'));
            }
            return Center(child: Text('Erreur: $msg'));
          }

          final tickets = snap.data ?? [];
          if (tickets.isEmpty) {
            return const Center(child: Text('Aucun billet à venir.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final t = tickets[i];
                final film = (t['film'] ?? t['titre'] ?? 'Film').toString();
                final dateStr = (t['date'] ?? t['datetime'] ?? '').toString();

                DateTime? dt;
                try {
                  dt = DateTime.tryParse(dateStr)?.toLocal();
                } catch (_) {
                  dt = null;
                }
                final dateFormatted = dt != null ? fmt.format(dt) : dateStr;

                final resId = int.tryParse(
                      (t['reservationId'] ?? t['reservation_id'] ?? t['id']).toString(),
                    ) ??
                    0;

                return ListTile(
                  title: Text(film),
                  subtitle: Text(dateFormatted),
                  trailing: const Icon(Icons.qr_code),
                  onTap: () async {
                    try {
                      final qr = await widget.api.fetchQrData(resId);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QrCodeScreen(qrData: qr)),
                      );
                    } catch (e) {
                      final msg = e.toString();
                      if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
                        _forceLogin("Session expirée. Merci de vous reconnecter.");
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur QR: $msg')),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
