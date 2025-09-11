import 'dart:collection';
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'incidents_screen.dart';
import '../auth/auth_store.dart';
import 'login_screen.dart';

class SallesScreen extends StatefulWidget {
  final ApiClient api;
  const SallesScreen({super.key, required this.api});

  @override
  State<SallesScreen> createState() => _SallesScreenState();
}

class _SallesScreenState extends State<SallesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  // DA sombre
  final _bg = const Color(0xFF0E0E0E);
  final _fg = const Color(0xFFEDEDED);
  final _muted = const Color(0xFF9E9E9E);
  final _card = const Color(0xFF171717);
  final _accent = const Color(0xFFF39C12);

  // État d’expansion par cinéma
  final Set<String> _expanded = <String>{};

  late final AuthStore _auth;

  @override
  void initState() {
    super.initState();
    _auth = AuthStore(widget.api);
    _future = widget.api.fetchSalles();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.api.fetchSalles();
    });
    await _future;
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      (_) => false,
    );
  }

  // Transforme la liste brute en { "Cinema A": [salles...], "Cinema B": [...] } trié
  LinkedHashMap<String, List<Map<String, dynamic>>> _groupByCinema(
    List<Map<String, dynamic>> salles,
  ) {
    // tri salles par nom
    salles.sort((a, b) {
      final an = (a['nom'] ?? a['name'] ?? '').toString().toLowerCase();
      final bn = (b['nom'] ?? b['name'] ?? '').toString().toLowerCase();
      return an.compareTo(bn);
    });

    final Map<String, List<Map<String, dynamic>>> tmp = {};
    for (final s in salles) {
      final cinema = (s['cinema'] is Map && s['cinema']?['nom'] != null)
          ? s['cinema']['nom'].toString()
          : (s['cinema'] ?? 'Cinéma').toString();
      tmp.putIfAbsent(cinema, () => []);
      tmp[cinema]!.add(s);
    }

    // tri des cinémas
    final keys = tmp.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final linked = LinkedHashMap<String, List<Map<String, dynamic>>>();
    for (final k in keys) {
      linked[k] = tmp[k]!;
    }
    return linked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text('Salles',
            style: TextStyle(color: _fg, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            color: _fg,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            color: _fg,
            tooltip: 'Déconnexion',
          ),
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
            // Si le backend renvoie 401 → renvoi au login
            if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _logout();
              });
              return const SizedBox.shrink();
            }
            return Center(
              child: Text('Erreur: $msg', style: TextStyle(color: _muted)),
            );
          }

          final salles = snap.data ?? [];
          if (salles.isEmpty) {
            return Center(
              child: Text('Aucune salle.', style: TextStyle(color: _muted)),
            );
          }

          final grouped = _groupByCinema(salles);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final cinema = grouped.keys.elementAt(i);
              final sallesDuCinema = grouped[cinema]!;
              final expanded = _expanded.contains(cinema);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    // Header du cinéma
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          if (expanded) {
                            _expanded.remove(cinema);
                          } else {
                            _expanded.add(cinema);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              expanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: _fg,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                cinema,
                                style: TextStyle(
                                  color: _fg,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${sallesDuCinema.length} salle${sallesDuCinema.length > 1 ? 's' : ''}',
                                style: TextStyle(color: _muted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Corps (salles) si déplié
                    if (expanded)
                      Column(
                        children: List.generate(sallesDuCinema.length, (idx) {
                          final s = sallesDuCinema[idx];
                          final id = int.tryParse((s['id'] ?? '0').toString()) ?? 0;
                          final nom =
                              (s['nom'] ?? s['name'] ?? 'Salle').toString();

                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              12,
                              idx == 0 ? 0 : 6,
                              12,
                              idx == sallesDuCinema.length - 1 ? 12 : 6,
                            ),
                            child: Material(
                              color: const Color(0xFF1D1D1D),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IncidentsScreen(
                                        api: widget.api,
                                        salleId: id,
                                        salleNom: '$nom — $cinema',
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.meeting_room,
                                          color: Colors.white70),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nom,
                                          style: TextStyle(
                                              color: _fg,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right, color: _accent),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
