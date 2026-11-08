import '../../core/api_client.dart';
import '../../core/token_storage.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.imageUrl,
    this.bio,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        username: json['username'] as String?,
        imageUrl: json['image_url'] as String?,
        bio: json['bio'] as String?,
      );

  final int id;
  final String email;
  final String? fullName;
  final String? username;
  final String? imageUrl;
  final String? bio;

  /// Best display name available: full name, falling back to
  /// username, then the local part of the email — mirrors the
  /// backend's own Accounts.display_name/1 fallback chain.
  String get displayName =>
      (fullName?.isNotEmpty ?? false) ? fullName! : (username?.isNotEmpty ?? false) ? username! : email.split('@').first;

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Talks to `viso_backend`'s /api/register, /api/login, /api/logout and
/// /api/me, and persists the bearer token it gets back.
class AuthRepository {
  AuthRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<AuthUser> register({required String email, required String password}) async {
    final json = await _api.post('/register', data: {
      'email': email,
      'password': password,
    });
    return _saveTokenAndReturnUser(json);
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final json = await _api.post('/login', data: {
      'email': email,
      'password': password,
    });
    return _saveTokenAndReturnUser(json);
  }

  Future<AuthUser?> currentUser() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;

    final json = await _api.get('/me');
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateProfile({
    String? fullName,
    String? username,
    String? imageUrl,
    String? bio,
  }) async {
    final data = <String, dynamic>{
      'full_name': ?fullName,
      'username': ?username,
      'image_url': ?imageUrl,
      'bio': ?bio,
    };
    final json = await _api.patch('/me', data: data);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _api.delete('/logout');
    await _tokenStorage.clearToken();
  }

  Future<AuthUser> _saveTokenAndReturnUser(Map<String, dynamic> json) async {
    final token = json['token'] as String;
    await _tokenStorage.saveToken(token);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }
}
