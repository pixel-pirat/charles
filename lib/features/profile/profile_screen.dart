import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../widgets/post_card.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/auth_controller.dart';
import '../posts/posts_controller.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final myPosts = ref.watch(myPostsControllerProvider);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(user.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myPostsControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProfileAvatar(imageUrl: user.imageUrl, initials: user.initials, radius: 40),
                    const SizedBox(height: 12),
                    Text(user.displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    if (user.username != null)
                      Text('@${user.username}', style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary)),
                    if ((user.bio ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(user.bio!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppTheme.textPrimary)),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                      child: const Text('Edit profile'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Posts', style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
              ),
            ),
            myPosts.when(
              data: (posts) => posts.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text("You haven't posted anything yet.", style: TextStyle(color: AppTheme.textSecondary))),
                      ),
                    )
                  : SliverList.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) => PostCard(
                        post: posts[index],
                        onLike: () => ref.read(myPostsControllerProvider.notifier).toggleLike(posts[index].id),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
