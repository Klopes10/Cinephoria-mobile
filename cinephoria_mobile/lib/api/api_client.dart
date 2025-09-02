import 'dart:convert';
import 'dart:io'; // pour SocketException / HttpException
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? _token;

  void setToken(String? token) => _token = token;
  Uri _u(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  /// Connexion utilisateur → retourne le JWT
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

      // Extraire un message d’erreur lisible si possible
      try {
        final err = jsonDecode(res.body);
        final msg = (err['message'] ?? err['error'] ?? res.body).toString();
        throw Exception('Login échoué (${res.statusCode}) : $msg');
      } catch (_) {
        throw Exception('Login échoué (${res.statusCode})');
      }
    } on SocketException {
      throw Exception("Impossible d’atteindre l’API (${AppConfig.baseUrl}).");
    } on HttpException {
      throw Exception("Erreur HTTP lors de la connexion.");
    } on FormatException {
      throw Exception("Réponse illisible du serveur.");
    }
  }

  /// Récupérer les séances réservées à venir
  Future<List<Map<String, dynamic>>> fetchMyUpcomingTickets() async {
    final res = await _http
        .get(
          _u('/api/me/seances?from=today'),
          headers: {'Authorization': 'Bearer ${_token ?? ''}'},
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    if (res.statusCode == 401) {
      // Pour forcer la redirection au login côté UI
      throw Exception('SESSION_EXPIRED');
    }
    throw Exception('Erreur tickets (${res.statusCode})');
  }

  /// Récupérer les données QR d’une réservation
  Future<String> fetchQrData(int reservationId) async {
    final res = await _http
        .get(
          _u('/api/reservations/$reservationId'),
          headers: {'Authorization': 'Bearer ${_token ?? ''}'},
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['qrcodeData'] ?? data['qr'] ?? 'CINE-$reservationId')
          .toString();
    }
    if (res.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }
    throw Exception('Erreur QR (${res.statusCode})');
  }
}
