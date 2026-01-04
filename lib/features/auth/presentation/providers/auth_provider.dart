import 'package:flutter/foundation.dart';
import '../../data/auth_repository_impl.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isLoading = false;
  String? _userId;

  AuthProvider(this._repository) {
    _userId = _repository.currentUserId();
  }

  bool get isLoading => _isLoading;
  String? get userId => _userId;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _repository.signIn(email, password);
      _userId = id;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _repository.register(email, password);
      _userId = id;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.signOut();
    _userId = null;
    notifyListeners();
  }
}
