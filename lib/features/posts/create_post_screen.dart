import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'posts_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textController = TextEditingController();
  XFile? _pickedImage;
  bool _posting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _post() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pickedImage == null) {
      setState(() => _error = 'Write something or add a photo.');
      return;
    }

    setState(() {
      _posting = true;
      _error = null;
    });

    try {
      final mediaUrls = <String>[];
      if (_pickedImage != null) {
        final url = await ref.read(apiClientProvider).uploadFile(_pickedImage!.path);
        mediaUrls.add(url);
      }

      final post = await ref.read(postsRepositoryProvider).createPost(
            text: text,
            mediaUrls: mediaUrls,
            mediaType: mediaUrls.isEmpty ? 'none' : 'image',
          );

      ref.read(myPostsControllerProvider.notifier).addPost(post);
      await ref.read(feedControllerProvider.notifier).refresh();

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not post. Try again.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New post'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _post,
            child: _posting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 6,
              autofocus: true,
              decoration: const InputDecoration(hintText: "What's on your mind?", border: InputBorder.none),
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(_pickedImage!.path), height: 200, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ),
                  IconButton(
                    icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)),
                    onPressed: () => setState(() => _pickedImage = null),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            IconButton(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
