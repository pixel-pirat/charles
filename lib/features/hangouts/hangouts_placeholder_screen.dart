import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// No backend exists for hangouts/communities yet (the old app's
/// version of this screen wasn't backed by anything real either) —
/// shown honestly as "coming soon" rather than faked with mock data.
class HangoutsPlaceholderScreen extends StatelessWidget {
  const HangoutsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hangouts')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textMuted),
              SizedBox(height: 16),
              Text('Hangouts are coming soon.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary)),
              SizedBox(height: 6),
              Text(
                "We're still building this part of the app.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
