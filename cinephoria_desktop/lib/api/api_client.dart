import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:async';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();
  final http.Client _http;

  String? _token;
  void setToken(String? t) => _token = t;

  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  // --- AUTH ---
  Future<String> login(String email, String password) async {
    try {
      final res = await _http
          .post(
            _u('/api/login_check'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token'] ?? data['id_token'];
        if (token is String && token.isNotEmpty) {
          _token = token;
          return token;
        }
        throw Exception('Réponse login sans token.');
      }

      // erreur lisible si possible
      try {
        final err = jsonDecode(res.body);
        final msg = (err['message'] ?? err['error'] ?? res.body).toString();
        throw Exception('Login échoué (${res.statusCode}) : $msg');
      } catch (_) {
        throw Exception('Login échoué (${res.statusCode})');
      }
    } on SocketException {
      throw Exception("API injoignable (${AppConfig.baseUrl}).");
    } on HttpException {
      throw Exception("Erreur HTTP.");
    } on FormatException {
      throw Exception("Réponse illisible du serveur.");
    } on TimeoutException {
      throw Exception("Délai dépassé (timeout).");
    }
  }

  Map<String, String> get _authHeaders =>
      {'Authorization': 'Bearer ${_token ?? ''}'};

  // --- EXEMPLES QUI SERVIRONT ENSUITE (salles/incidents) ---
  Future<List<Map<String, dynamic>>> fetchSalles() async {
    final r = await _http
        .get(_u('/api/salles'), headers: _authHeaders)
        .timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    if (r.statusCode == 401) throw Exception('SESSION_EXPIRED');
    throw Exception('Erreur salles (${r.statusCode})');
  }

  Future<List<Map<String, dynamic>>> fetchIncidentsBySalle(int salleId) async {
    final r = await _http
        .get(_u('/api/salles/$salleId/incidents'), headers: _authHeaders)
        .timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) {
      final list = jsonDecode(r.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    if (r.statusCode == 401) throw Exception('SESSION_EXPIRED');
    throw Exception('Erreur incidents (${r.statusCode})');
  }

  Future<void> createIncident({
    required int salleId,
    required String type,
    String? siege,
    required String description,
  }) async {
    final r = await _http
        .post(
          _u('/api/incidents'),
          headers: {
            'Content-Type': 'application/json',
            ..._authHeaders,
          },
          body: jsonEncode({
            'salleId': salleId,
            'type': type,
            'siege': siege,
            'description': description,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode == 201) return;
    if (r.statusCode == 401) throw Exception('SESSION_EXPIRED');
    try {
      final err = jsonDecode(r.body);
      final msg = (err['message'] ?? err['error'] ?? r.body).toString();
      throw Exception('Création incident échouée (${r.statusCode}) : $msg');
    } catch (_) {
      throw Exception('Création incident échouée (${r.statusCode})');
    }
  }
}
