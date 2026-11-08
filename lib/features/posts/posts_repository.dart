import '../../core/api_client.dart';
import 'post_model.dart';

class PostsRepository {
  PostsRepository(this._api);

  final ApiClient _api;

  Future<PostItem> createPost({required String text, List<String> mediaUrls = const [], String mediaType = 'none'}) async {
    final json = await _api.post('/posts', data: {
      'text': text,
      'media_urls': mediaUrls,
      'media_type': mediaType,
    });
    return PostItem.fromJson(json['post'] as Map<String, dynamic>);
  }

  Future<List<PostItem>> getFeed({int limit = 20, int offset = 0}) async {
    final json = await _api.get('/posts/feed', query: {'limit': limit, 'offset': offset});
    return (json['posts'] as List).map((p) => PostItem.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<List<PostItem>> getMyPosts() async {
    final json = await _api.get('/posts/mine');
    return (json['posts'] as List).map((p) => PostItem.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<int> toggleLike(int postId) async {
    final json = await _api.post('/posts/$postId/like');
    return json['like_count'] as int;
  }

  Future<void> recordView(int postId) async {
    await _api.post('/posts/$postId/view');
  }
}
