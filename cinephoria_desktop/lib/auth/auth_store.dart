import '../api/api_client.dart';

class AuthStore {
  AuthStore(this._api);
  final ApiClient _api;

  Future<void> login(String email, String password) async {
    final token = await _api.login(email, password);
    _api.setToken(token);
  }

  Future<void> logout() async {
    _api.setToken(null);
  }
}
