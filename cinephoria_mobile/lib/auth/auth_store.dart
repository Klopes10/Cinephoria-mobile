import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

class AuthStore {
  AuthStore(this._api);

  final ApiClient _api;
  final _storage = const FlutterSecureStorage();
  static const _kToken = 'jwt_token';

  Future<void> init() async {
    final t = await _storage.read(key: _kToken);
    if (t != null) _api.setToken(t);
  }

  Future<void> login(String email, String password) async {
    final token = await _api.login(email, password);
    await _storage.write(key: _kToken, value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: _kToken);
    _api.setToken(null);
  }
}
