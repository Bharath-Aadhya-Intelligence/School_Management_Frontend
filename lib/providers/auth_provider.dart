import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _token;
  String? _classId;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get token => _token;
  String? get classId => _classId;
  String? get email => _email;

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _isAdmin = prefs.getBool('is_admin') ?? false;
    _classId = prefs.getString('class_id');
    _email = prefs.getString('email');
    _isLoggedIn = _token != null;
    notifyListeners();
  }

  Future<String?> login(String email, String password, bool isAdmin) async {
    try {
      final endpoint = isAdmin ? '/auth/admin/login' : '/auth/staff/login';
      final result = await ApiClient.post(
        endpoint,
        {'email': email, 'password': password},
        withAuth: false,
      );
      final response = TokenResponse.fromJson(result);

      _token = response.accessToken;
      _isAdmin = response.role == 'admin';
      _classId = response.classId;
      _email = email;
      _isLoggedIn = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      await prefs.setBool('is_admin', _isAdmin);
      if (_classId != null) await prefs.setString('class_id', _classId!);
      await prefs.setString('email', email);

      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {}

    _token = null;
    _isAdmin = false;
    _classId = null;
    _email = null;
    _isLoggedIn = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }
}
