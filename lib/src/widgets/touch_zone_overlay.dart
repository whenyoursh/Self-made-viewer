import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/comic_session_provider.dart';

/// Divides the screen into Left (35%), Center (30%), Right (35%) touch zones
class TouchZoneOverlay extends ConsumerWidget {
  const TouchZoneOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(comicSessionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Left Zone (35%)
            Expanded(
              flex: 35,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => notifier.handleTouchZone(isLeft: true),
                child: const SizedBox.expand(),
              ),
            ),
            // Center Zone (30%) - Toggle Menu/Controls
            Expanded(
              flex: 30,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => notifier.toggleControls(),
                child: const SizedBox.expand(),
              ),
            ),
            // Right Zone (35%)
            Expanded(
              flex: 35,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => notifier.handleTouchZone(isLeft: false),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}
