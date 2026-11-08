import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'post_model.dart';
import 'posts_repository.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  return PostsRepository(ref.watch(apiClientProvider));
});

/// The ranked home feed.
final feedControllerProvider = AsyncNotifierProvider<FeedController, List<PostItem>>(FeedController.new);

class FeedController extends AsyncNotifier<List<PostItem>> {
  @override
  Future<List<PostItem>> build() => ref.read(postsRepositoryProvider).getFeed();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(postsRepositoryProvider).getFeed());
  }

  /// Optimistically flips like state/count locally, then reconciles
  /// with the server's real count once the request returns.
  Future<void> toggleLike(int postId) async {
    final posts = state.value;
    if (posts == null) return;

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final original = posts[index];
    final optimistic = original.copyWith(
      isLikedByMe: !original.isLikedByMe,
      likeCount: original.isLikedByMe ? original.likeCount - 1 : original.likeCount + 1,
    );
    state = AsyncValue.data(_replace(posts, index, optimistic));

    final newCount = await ref.read(postsRepositoryProvider).toggleLike(postId);
    final latest = state.value;
    if (latest == null) return;
    final latestIndex = latest.indexWhere((p) => p.id == postId);
    if (latestIndex == -1) return;
    state = AsyncValue.data(_replace(latest, latestIndex, latest[latestIndex].copyWith(likeCount: newCount)));
  }
}

/// The signed-in user's own posts (Profile screen).
final myPostsControllerProvider = AsyncNotifierProvider<MyPostsController, List<PostItem>>(MyPostsController.new);

class MyPostsController extends AsyncNotifier<List<PostItem>> {
  @override
  Future<List<PostItem>> build() => ref.read(postsRepositoryProvider).getMyPosts();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(postsRepositoryProvider).getMyPosts());
  }

  void addPost(PostItem post) {
    final current = state.value ?? [];
    state = AsyncValue.data([post, ...current]);
  }

  Future<void> toggleLike(int postId) async {
    final posts = state.value;
    if (posts == null) return;

    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final original = posts[index];
    final optimistic = original.copyWith(
      isLikedByMe: !original.isLikedByMe,
      likeCount: original.isLikedByMe ? original.likeCount - 1 : original.likeCount + 1,
    );
    state = AsyncValue.data(_replace(posts, index, optimistic));

    final newCount = await ref.read(postsRepositoryProvider).toggleLike(postId);
    final latest = state.value;
    if (latest == null) return;
    final latestIndex = latest.indexWhere((p) => p.id == postId);
    if (latestIndex == -1) return;
    state = AsyncValue.data(_replace(latest, latestIndex, latest[latestIndex].copyWith(likeCount: newCount)));
  }
}

List<PostItem> _replace(List<PostItem> posts, int index, PostItem replacement) {
  final copy = [...posts];
  copy[index] = replacement;
  return copy;
}
