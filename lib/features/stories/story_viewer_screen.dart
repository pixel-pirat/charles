import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stories_controller.dart';
import 'story_model.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.group});

  final StoryGroup group;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markViewed(0));
  }

  void _markViewed(int index) {
    ref.read(storiesControllerProvider.notifier).markViewed(widget.group.stories[index].id);
  }

  void _advance() {
    if (_index < widget.group.stories.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _retreat() {
    if (_index > 0) {
      _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.group.stories;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: stories.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _markViewed(i);
            },
            itemBuilder: (context, i) {
              final story = stories[i];
              return GestureDetector(
                onTapUp: (details) {
                  final isLeftSide = details.localPosition.dx < MediaQuery.of(context).size.width / 2;
                  isLeftSide ? _retreat() : _advance();
                },
                child: Center(
                  child: Image.network(
                    story.mediaUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 48,
            left: 12,
            right: 12,
            child: Row(
              children: List.generate(
                stories.length,
                (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _index ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 12,
            child: Text(
              widget.group.authorName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Positioned(
            top: 52,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
