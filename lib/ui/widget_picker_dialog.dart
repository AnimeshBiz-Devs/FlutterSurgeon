import 'package:flutter/material.dart';
import '../models/widget_type.dart';

/// Dialog for picking a widget type to add as a child.
class WidgetPickerDialog extends StatelessWidget {
  const WidgetPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(title: 'Add Widget'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: WidgetCategory.values
                      .where((c) => c != WidgetCategory.root)
                      .map((cat) => _CategorySection(category: cat))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for picking a WRAPPER widget type (single-child only).
class WrapPickerDialog extends StatelessWidget {
  const WrapPickerDialog({super.key});

  static const _wrapTypes = [
    WidgetType.center,
    WidgetType.padding,
    WidgetType.container,
    WidgetType.align,
    WidgetType.expanded,
    WidgetType.sizedBox,
    WidgetType.clipRRect,
    WidgetType.gestureDetector,
    WidgetType.inkWell,
    WidgetType.card,
    WidgetType.safeArea,
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(title: 'Wrap with...'),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _wrapTypes
                      .map((t) => _WidgetChip(type: t))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, size: 16, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final WidgetCategory category;
  const _CategorySection({required this.category});

  static const _catNames = {
    WidgetCategory.root: 'Root',
    WidgetCategory.layoutMulti: 'Layout — Multi Child',
    WidgetCategory.layoutSingle: 'Layout — Single Child',
    WidgetCategory.display: 'Display',
    WidgetCategory.input: 'Input & Buttons',
    WidgetCategory.navigation: 'Navigation',
    WidgetCategory.decoration: 'Decoration',
  };

  @override
  Widget build(BuildContext context) {
    final widgets = WidgetType.values
        .where((t) => t.category == category && !t.isScaffoldSlotOnly)
        .toList();

    if (widgets.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            _catNames[category] ?? category.name,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widgets.map((t) => _WidgetChip(type: t)).toList(),
        ),
      ],
    );
  }
}

class _WidgetChip extends StatelessWidget {
  final WidgetType type;
  const _WidgetChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: const Color(0xFF2A2A45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(type.iconChar, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            type.displayName,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
      onPressed: () => Navigator.pop(context, type),
    );
  }
}
