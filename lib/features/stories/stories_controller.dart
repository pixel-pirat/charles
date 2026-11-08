import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'stories_repository.dart';
import 'story_model.dart';

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository(ref.watch(apiClientProvider));
});

final storiesControllerProvider = AsyncNotifierProvider<StoriesController, List<StoryGroup>>(StoriesController.new);

class StoriesController extends AsyncNotifier<List<StoryGroup>> {
  @override
  Future<List<StoryGroup>> build() => ref.read(storiesRepositoryProvider).getFeed();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(storiesRepositoryProvider).getFeed());
  }

  Future<void> markViewed(int storyId) async {
    await ref.read(storiesRepositoryProvider).markViewed(storyId);
    await refresh();
  }
}
