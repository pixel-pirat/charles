import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/stories_row.dart';
import '../auth/auth_controller.dart';
import '../posts/create_post_screen.dart';
import '../posts/posts_controller.dart';
import '../stories/stories_controller.dart';
import '../stories/story_viewer_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.read(feedControllerProvider.notifier).refresh(),
      ref.read(storiesControllerProvider.notifier).refresh(),
    ]);
  }

  Future<void> _addStory(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final url = await ref.read(apiClientProvider).uploadFile(file.path);
      await ref.read(storiesRepositoryProvider).createStory(mediaUrl: url, mediaType: 'image');
      await ref.read(storiesControllerProvider.notifier).refresh();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not post your story.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(feedControllerProvider);
    final stories = ref.watch(storiesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: stories.when(
                  data: (groups) => StoriesRow(
                    groups: groups,
                    onTapAddStory: () => _addStory(context, ref),
                    onTapGroup: (group) => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => StoryViewerScreen(group: group)),
                    ),
                  ),
                  loading: () => const SizedBox(height: 96),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            feed.when(
              data: (posts) => posts.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text('No posts yet — be the first to share something.', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                    )
                  : SliverList.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return PostCard(
                          post: post,
                          onLike: () => ref.read(feedControllerProvider.notifier).toggleLike(post.id),
                        );
                      },
                    ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (_, _) => SliverFillRemaining(
                child: Center(
                  child: TextButton(onPressed: () => _refresh(ref), child: const Text('Could not load the feed — tap to retry')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
