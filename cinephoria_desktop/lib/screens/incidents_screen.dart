import 'package:flutter/material.dart';
import '../api/api_client.dart';

class IncidentsScreen extends StatefulWidget {
  const IncidentsScreen({
    super.key,
    required this.api,
    required this.salleId,
    required this.salleNom,
  });

  final ApiClient api;
  final int salleId;
  final String salleNom;

  @override
  State<IncidentsScreen> createState() => _IncidentsScreenState();
}

class _IncidentsScreenState extends State<IncidentsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  // DA sombre
  final _bg = const Color(0xFF0E0E0E);
  final _fg = const Color(0xFFEDEDED);
  final _muted = const Color(0xFF9E9E9E);
  final _card = const Color(0xFF171717);
  final _accent = const Color(0xFFF39C12);

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchIncidentsBySalle(widget.salleId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.api.fetchIncidentsBySalle(widget.salleId);
    });
    await _future;
  }

  Future<void> _openCreateDialog() async {
    final form = await showDialog<_IncidentFormResult>(
      context: context,
      builder: (_) => _IncidentFormDialog(accent: _accent),
    );
    if (form == null) return;

    try {
      await widget.api.createIncident(
        salleId: widget.salleId,
        titre: form.titre,
        description: form.description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Incident enregistré.'),
        ),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Erreur: $msg'),
        ),
      );
      if (msg.contains('SESSION_EXPIRED') || msg.contains('401')) {
        Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Incidents — ${widget.salleNom}',
          style: TextStyle(color: _fg, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), color: _fg),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateDialog,
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        label: const Text('Signaler'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Erreur: ${snap.error}', style: TextStyle(color: _muted)),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Text('Aucun incident pour cette salle.', style: TextStyle(color: _muted)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final it = list[i];

              final titre = (it['titre'] ?? '').toString();
              final desc = (it['description'] ?? '').toString();
              final resolu = (it['resolu'] == true);
              final createdAt = (it['dateSignalement'] ?? it['createdAt'] ?? '').toString();

              // Fallback d’affichage si pas de titre
              final displayTitle = titre.isNotEmpty
                  ? titre
                  : (desc.isNotEmpty ? (desc.length > 40 ? '${desc.substring(0, 40)}…' : desc) : 'Incident');

              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          resolu ? Icons.check_circle : Icons.error_outline,
                          color: resolu ? Colors.greenAccent : Colors.orangeAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(color: _fg, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(createdAt, style: TextStyle(color: _muted, fontSize: 12)),
                      ],
                    ),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(desc, style: TextStyle(color: _muted)),
                    ],
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

/// ---- Dialog de création ----

class _IncidentFormResult {
  _IncidentFormResult({required this.titre, required this.description});
  final String titre;
  final String description;
}

class _IncidentFormDialog extends StatefulWidget {
  const _IncidentFormDialog({required this.accent});
  final Color accent;

  @override
  State<_IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<_IncidentFormDialog> {
  final _titre = TextEditingController();
  final _desc  = TextEditingController();
  bool _sending = false;

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: widget.accent), // tu peux mettre _accent si tu veux garder l’orange
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF171717),
      titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
      contentTextStyle: const TextStyle(color: Colors.white70),
      title: const Text('Signaler un incident'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _titre,
              style: const TextStyle(color: Colors.white), // texte blanc
              decoration: _decoration('Titre (ex: Siège cassé rang C)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _desc,
              style: const TextStyle(color: Colors.white), // texte blanc
              decoration: _decoration('Description'),
              maxLines: 4,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.accent,
            foregroundColor: Colors.black,
          ),
          onPressed: _sending
              ? null
              : () {
                  final t = _titre.text.trim();
                  final d = _desc.text.trim();
                  if (t.isEmpty || d.isEmpty) return;
                  setState(() => _sending = true);
                  Navigator.pop(context, _IncidentFormResult(titre: t, description: d));
                },
          child: Text(_sending ? 'Envoi…' : 'Enregistrer'),
        ),
      ],
    );
  }
}

