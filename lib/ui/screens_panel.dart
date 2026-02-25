import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tree_provider.dart';

class ScreensPanel extends ConsumerWidget {
  const ScreensPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screens = ref.watch(widgetTreeProvider);
    final activeScreen = ref.watch(activeScreenProvider);

    return Container(
      width: 180,
      decoration: const BoxDecoration(
        color: Color(0xFF14142A),
        border: Border(right: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: 'Screens',
            action: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF7C83FF), size: 18),
              tooltip: 'New Screen',
              onPressed: () {
                final newName = 'Screen${screens.length + 1}';
                ref.read(widgetTreeProvider.notifier).addScreen(newName);
                ref.read(activeScreenProvider.notifier).state = newName;
                ref.read(selectedNodeIdProvider.notifier).state = null;
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: screens.keys.length,
              itemBuilder: (context, index) {
                final screenName = screens.keys.elementAt(index);
                final isActive = screenName == activeScreen;

                return InkWell(
                  onTap: () {
                    ref.read(activeScreenProvider.notifier).state = screenName;
                    ref.read(selectedNodeIdProvider.notifier).state = null;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF7C83FF).withValues(alpha: 0.15)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isActive
                              ? const Color(0xFF7C83FF)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            screenName,
                            style: TextStyle(
                              color: isActive
                                  ? const Color(0xFF7C83FF)
                                  : Colors.white70,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (screens.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 14),
                            color: Colors.white38,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (isActive) {
                                // If deleting active, switch to the first available one that isn't this one
                                final fallback = screens.keys.firstWhere(
                                  (k) => k != screenName,
                                );
                                ref.read(activeScreenProvider.notifier).state =
                                    fallback;
                              }
                              ref
                                  .read(widgetTreeProvider.notifier)
                                  .removeScreen(screenName);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _PanelHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
