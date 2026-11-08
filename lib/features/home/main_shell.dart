import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/main_bottom_nav_bar.dart';
import '../chat/chat_controller.dart';
import '../chat/chats_list_screen.dart';
import '../hangouts/hangouts_placeholder_screen.dart';
import '../profile/profile_screen.dart';
import '../users/discover_screen.dart';
import 'home_screen.dart';

/// Holds the bottom nav + page switching for the signed-in app
/// experience, and keeps the chat socket's lobby presence joined for
/// as long as the user is signed in (not just while Chats is open).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  static const _pages = [
    HomeScreen(),
    DiscoverScreen(),
    HangoutsPlaceholderScreen(),
    ChatsListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(chatSocketServiceProvider).joinLobby());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
