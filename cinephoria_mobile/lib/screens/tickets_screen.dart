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
  late AuthStore _auth;

  // Palette cohérente avec l'écran login
  final Color _bg = const Color(0xFF0E0E0E);
  final Color _fg = const Color(0xFFEDEDED);
  final Color _muted = const Color(0xFF9E9E9E);
  final Color _accent = const Color(0xFFF39C12);
  final Color _card = const Color(0xFF171717);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
      );
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() => _forceLogin("Déconnecté.");

  // URL affiche -> utilisable par l'émulateur
  String fixUrl(String url) {
    if (url.isEmpty) return url;
    final base = AppConfig.baseUrl;
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    url = url.replaceFirst('http://localhost:8080', b);
    if (!url.startsWith('http')) {
      final p = url.startsWith('/') ? url.substring(1) : url;
      return '$b/$p';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final dayFmt = DateFormat('EEE d MMM', 'fr_FR');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mes billets',
          style: TextStyle(color: _fg, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            color: _fg,
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            color: _fg,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (snap.hasError) {
            final msg = snap.error.toString();
            if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _forceLogin("Session expirée. Merci de vous reconnecter.");
              });
              return Center(
                child: Text('Session expirée…', style: TextStyle(color: _muted)),
              );
            }
            return Center(
              child: Text('Erreur: $msg', style: TextStyle(color: _muted)),
            );
          }

          final tickets = snap.data ?? [];
          if (tickets.isEmpty) {
            return Center(
              child: Text('Aucun billet à venir.', style: TextStyle(color: _muted)),
            );
          }

          return RefreshIndicator(
            color: _accent,
            backgroundColor: _card,
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              itemCount: tickets.length,
              itemBuilder: (context, i) {
                final t = tickets[i];

                final film       = (t['film'] ?? t['titre'] ?? 'Film').toString();
                final rawAffiche = (t['affiche'] ?? '').toString();
                final affiche    = fixUrl(rawAffiche);
                final salle      = (t['salle'] ?? '').toString();
                final seats      = (t['seats'] as List?)?.cast<String>() ?? [];

                final jour = (t['jour'] ?? '').toString();
                final hDeb = (t['heureDebut'] ?? '').toString();
                final hFin = (t['heureFin'] ?? '').toString();

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

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Erreur QR: $msg'),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Affiche
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: affiche.isNotEmpty
                                ? Image.network(
                                    affiche,
                                    width: 64,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    cacheWidth: 160,
                                    errorBuilder: (ctx, err, st) {
                                      debugPrint('IMG ERROR: $affiche -> $err');
                                      return Container(
                                        width: 64,
                                        height: 96,
                                        color: Colors.white10,
                                        child: const Icon(Icons.movie, size: 28, color: Colors.white70),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 64,
                                    height: 96,
                                    color: Colors.white10,
                                    child: const Icon(Icons.movie, size: 28, color: Colors.white70),
                                  ),
                          ),
                          const SizedBox(width: 12),

                          // Texte
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre
                                Text(
                                  film,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _fg,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Date + heures
                                Row(
                                  children: [
                                    Icon(Icons.event, size: 16, color: _muted),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$dayLabel  (${hDebShort.isNotEmpty ? hDebShort : "—"} – ${hFinShort.isNotEmpty ? hFinShort : "—"})',
                                      style: TextStyle(color: _muted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Salle
                                Row(
                                  children: [
                                    Icon(Icons.meeting_room, size: 16, color: _muted),
                                    const SizedBox(width: 6),
                                    Text('Salle: ${salle.isNotEmpty ? salle : "—"}',
                                        style: TextStyle(color: _muted)),
                                  ],
                                ),
                                if (seats.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.event_seat, size: 16, color: _muted),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Sièges: ${seats.join(', ')}',
                                          style: TextStyle(color: _muted),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // QR
                          const SizedBox(width: 8),
                          Icon(Icons.qr_code, color: _fg),
                        ],
                      ),
                    ),
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
