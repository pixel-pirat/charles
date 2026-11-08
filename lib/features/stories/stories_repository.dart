import '../../core/api_client.dart';
import 'story_model.dart';

class StoriesRepository {
  StoriesRepository(this._api);

  final ApiClient _api;

  Future<List<StoryGroup>> getFeed() async {
    final json = await _api.get('/stories');
    return (json['groups'] as List).map((g) => StoryGroup.fromJson(g as Map<String, dynamic>)).toList();
  }

  Future<int> createStory({required String mediaUrl, required String mediaType}) async {
    final json = await _api.post('/stories', data: {'media_url': mediaUrl, 'media_type': mediaType});
    return json['id'] as int;
  }

  Future<void> markViewed(int storyId) async {
    await _api.post('/stories/$storyId/view');
  }
}
