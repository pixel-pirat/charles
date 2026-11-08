import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/auth_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String? _imageUrl;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value!;
    _nameController = TextEditingController(text: user.fullName ?? '');
    _usernameController = TextEditingController(text: user.username ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _imageUrl = user.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(apiClientProvider).uploadFile(file.path);
      setState(() => _imageUrl = url);
    } catch (_) {
      setState(() => _error = 'Could not upload that photo.');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            username: _usernameController.text.trim(),
            bio: _bioController.text.trim(),
            imageUrl: _imageUrl,
          );
      ref.invalidate(authControllerProvider);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _changePhoto,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ProfileAvatar(imageUrl: _imageUrl, initials: ref.read(authControllerProvider).value!.initials, radius: 44),
                  if (_uploadingPhoto) const CircularProgressIndicator(),
                  if (!_uploadingPhoto)
                    const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 14, child: Icon(Icons.edit, size: 14))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
          const SizedBox(height: 12),
          TextField(controller: _bioController, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
