import '../../core/api_client.dart';
import 'user_model.dart';

class UsersRepository {
  UsersRepository(this._api);

  final ApiClient _api;

  Future<List<PublicUser>> search(String query) async {
    final json = await _api.get('/users/search', query: {'q': query});
    return (json['users'] as List).map((u) => PublicUser.fromJson(u as Map<String, dynamic>)).toList();
  }

  Future<PublicUser> show(int userId) async {
    final json = await _api.get('/users/$userId');
    return PublicUser.fromJson(json['user'] as Map<String, dynamic>);
  }
}
