import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../auth/auth_store.dart';
import '../config.dart';
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

  /// Rend l’URL d’affiche utilisable dans l’émulateur :
  /// - remplace localhost -> 10.0.2.2
  /// - construit une URL absolue si on reçoit un chemin relatif
  String fixUrl(String url) {
  if (url.isEmpty) return url;

  // Base de l’API côté émulateur (ex: http://10.0.2.2:8080)
  final base = AppConfig.baseUrl;
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;

  // 1) Si l’API renvoie une URL en localhost → remplace host/port par base
  url = url.replaceFirst('http://localhost:8080', b);

  // 2) Si c’est un chemin relatif (/uploads/... ou uploads/...), fabrique l’URL absolue
  if (!url.startsWith('http')) {
    final p = url.startsWith('/') ? url.substring(1) : url;
    return '$b/$p';
  }

  return url;
}


  @override
  Widget build(BuildContext context) {
    // NB: pense à avoir appelé initializeDateFormatting('fr_FR') dans main()
    final dayFmt = DateFormat('EEE d MMM', 'fr_FR');

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
            if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
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
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: tickets.length,
              itemBuilder: (context, i) {
                final t = tickets[i];

                final film       = (t['film'] ?? t['titre'] ?? 'Film').toString();
                final rawAffiche = (t['affiche'] ?? '').toString();
                final affiche    = fixUrl(rawAffiche);
                final salle      = (t['salle'] ?? '').toString();
                final seats      = (t['seats'] as List?)?.cast<String>() ?? [];

                // On s’appuie sur jour + heureDebut/heureFin pour éviter les décalages de fuseau
                final jour = (t['jour'] ?? '').toString();         // "2025-09-05"
                final hDeb = (t['heureDebut'] ?? '').toString();   // "20:00:00"
                final hFin = (t['heureFin'] ?? '').toString();     // "22:00:00"

                String dayLabel = jour;
                try {
                  if (jour.isNotEmpty) {
                    final d = DateTime.parse('$jour' 'T00:00:00');
                    dayLabel = dayFmt.format(d);
                  }
                } catch (_) {}

                final hDebShort = hDeb.length >= 5 ? hDeb.substring(0, 5) : hDeb;
                final hFinShort = hFin.length >= 5 ? hFin.substring(0, 5) : hFin;

                final resId = int.tryParse(
                      (t['reservationId'] ?? t['reservation_id'] ?? t['id']).toString(),
                    ) ??
                    0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: affiche.isNotEmpty
    ? ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          affiche,
          width: 60,
          height: 120,                // <— hauteur explicite
          fit: BoxFit.cover,
          cacheWidth: 120,           // <— downscale côté décodage (plus robuste)
          errorBuilder: (ctx, err, st) {
            debugPrint('IMG ERROR: $affiche -> $err');
            return const Icon(Icons.movie, size: 60);
          },
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 60,
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      )
    : const Icon(Icons.movie, size: 40),

                    title: Text(
                      film,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ex: "ven. 5 sept.  (20:00 – 22:00)"
                        Text(
                          '$dayLabel  (${hDebShort.isNotEmpty ? hDebShort : "—"} – ${hFinShort.isNotEmpty ? hFinShort : "—"})',
                        ),
                        Text('Salle: ${salle.isNotEmpty ? salle : "—"}'),
                        if (seats.isNotEmpty) Text('Sièges: ${seats.join(', ')}'),
                      ],
                    ),
                    trailing: const Icon(Icons.qr_code),
                    onTap: () async {
                      try {
                        final qr = await widget.api.fetchQrData(resId);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QrCodeScreen(qrData: qr),
                          ),
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
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
