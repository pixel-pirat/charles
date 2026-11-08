import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows the user's uploaded avatar image, or a colored initials circle
/// when no image has been uploaded yet (the common case, since we don't
/// ask new users for a photo at sign-up).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.imageUrl, required this.initials, required this.radius});

  final String? imageUrl;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (e, s) {},
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primary,
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: radius * 0.6),
      ),
    );
  }
}
