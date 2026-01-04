import '../../../data/datasources/remote/auth_service.dart';

abstract class AuthRepository {
  Future<String?> signIn(String email, String password);
  Future<String?> register(String email, String password);
  Future<void> signOut();
  String? currentUserId();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<String?> signIn(String email, String password) async {
    return await _authService.signIn(email, password);
  }

  @override
  Future<String?> register(String email, String password) async {
    return await _authService.register(email, password);
  }

  @override
  Future<void> signOut() async {
    return await _authService.signOut();
  }

  @override
  String? currentUserId() => _authService.currentUserId;
}
