import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/tree_provider.dart';
import 'widget_picker_dialog.dart';

class LayersPanel extends ConsumerWidget {
  const LayersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = ref.watch(activeScreenProvider);
    final screens = ref.watch(widgetTreeProvider);
    final root = screens[activeScreen];
    final selectedId = ref.watch(selectedNodeIdProvider);

    return Container(
      width: 228,
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'Layers',
            action: root == null
                ? IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFF7C83FF),
                      size: 18,
                    ),
                    tooltip: 'Add root Scaffold',
                    onPressed: () => _addRootScaffold(ref),
                  )
                : null,
          ),
          Expanded(
            child: root == null
                ? const _EmptyLayers()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _NodeTile(
                        node: root,
                        depth: 0,
                        selectedId: selectedId,
                        ref: ref,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _addRootScaffold(WidgetRef ref) {
    final activeScreen = ref.read(activeScreenProvider);
    ref.read(widgetTreeProvider.notifier).addScreen(activeScreen);
    final root = ref.read(widgetTreeProvider)[activeScreen]!;
    ref.read(selectedNodeIdProvider.notifier).state = root.id;
  }
}

class _NodeTile extends StatefulWidget {
  final WidgetNode node;
  final int depth;
  final String? selectedId;
  final WidgetRef ref;

  const _NodeTile({
    required this.node,
    required this.depth,
    required this.selectedId,
    required this.ref,
  });

  @override
  State<_NodeTile> createState() => _NodeTileState();
}

class _NodeTileState extends State<_NodeTile> {
  bool _expanded = true;
  bool _renaming = false;
  late TextEditingController _renameCtrl;

  @override
  void initState() {
    super.initState();
    _renameCtrl = TextEditingController(text: widget.node.label);
  }

  @override
  void dispose() {
    _renameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final isSelected = widget.selectedId == node.id;
    final hasChildren = node.allDirectChildren.isNotEmpty;
    final indent = widget.depth * 14.0;

    final tileRow = DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        final draggedId = details.data;
        if (draggedId == node.id) return false;
        if (node.isLeaf) return false;

        // Prevent infinite loops (dragging into own descendant)
        final activeScreen = widget.ref.read(activeScreenProvider);
        final root = widget.ref.read(widgetTreeProvider)[activeScreen];
        if (root != null) {
          WidgetNode? findNode(WidgetNode current, String id) {
            if (current.id == id) return current;
            for (final c in current.allDirectChildren) {
              final found = findNode(c, id);
              if (found != null) return found;
            }
            return null;
          }

          final draggedNode = findNode(root, draggedId);
          if (draggedNode != null && findNode(draggedNode, node.id) != null) {
            return false;
          }
        }

        if (node.isSingleChild &&
            node.child != null &&
            node.child!.id != draggedId)
          return false;
        if (node.isScaffold &&
            node.child != null &&
            node.child!.id != draggedId)
          return false;

        return true;
      },
      onAcceptWithDetails: (details) {
        final err = widget.ref
            .read(widgetTreeProvider.notifier)
            .moveNode(details.data, node.id);
        if (err != null && context.mounted) {
          _showError(context, err);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        final feedbackWidget = Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C83FF).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(node.type.iconChar, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 6),
                Text(
                  _getSlotLabel(node, widget.ref),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        );

        final dragHandle = Draggable<String>(
          data: node.id,
          feedback: feedbackWidget,
          childWhenDragging: const Icon(
            Icons.drag_indicator,
            size: 14,
            color: Colors.transparent,
          ),
          child: const MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Icon(Icons.drag_indicator, size: 14, color: Colors.white30),
          ),
        );

        return GestureDetector(
          onTap: () =>
              widget.ref.read(selectedNodeIdProvider.notifier).state = node.id,
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, details.globalPosition),
          child: Container(
            color: isSelected
                ? const Color(0xFF7C83FF).withValues(alpha: 0.22)
                : (isHovered
                      ? const Color(0xFF4ECDC4).withValues(alpha: 0.15)
                      : Colors.transparent),
            child: Row(
              children: [
                SizedBox(width: indent),
                // Drag Handle
                if (widget.depth > 0) dragHandle else const SizedBox(width: 14),
                // Expand toggle
                SizedBox(
                  width: 16,
                  child: hasChildren
                      ? GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Icon(
                            _expanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: 16,
                            color: Colors.white54,
                          ),
                        )
                      : const SizedBox(),
                ),
                // Icon + label
                const SizedBox(width: 2),
                Text(node.type.iconChar, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 5),
                Expanded(
                  child: _renaming
                      ? _RenameField(
                          controller: _renameCtrl,
                          onSubmit: (v) {
                            widget.ref
                                .read(widgetTreeProvider.notifier)
                                .renameNode(node.id, v);
                            setState(() => _renaming = false);
                          },
                          onCancel: () => setState(() => _renaming = false),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getSlotLabel(node, widget.ref),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFFADB0FF)
                                      : Colors.white70,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ..._buildWarnings(node),
                          ],
                        ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tileRow,
        if (_expanded && hasChildren)
          ...node.allDirectChildren.map(
            (child) => _NodeTile(
              node: child,
              depth: widget.depth + 1,
              selectedId: widget.selectedId,
              ref: widget.ref,
            ),
          ),
      ],
    );
  }

  List<Widget> _buildWarnings(WidgetNode node) {
    final warnings = <Widget>[];
    // Text with empty content
    if (node.type == WidgetType.text &&
        (node.props['content'] as String? ?? '').isEmpty) {
      warnings.add(
        const Tooltip(
          message: 'Text content is empty',
          child: Icon(Icons.warning_amber, size: 12, color: Color(0xFFFFC107)),
        ),
      );
    }
    return warnings;
  }

  String _getSlotLabel(WidgetNode node, WidgetRef ref) {
    final activeScreen = ref.read(activeScreenProvider);
    final root = ref.read(widgetTreeProvider)[activeScreen];
    final parentId = _findParentId(root, node.id);
    if (parentId == null) return node.label;

    if (root == null) return node.label;

    // Re-implementing a simple parent lookup here to check slots
    WidgetNode? findParent(WidgetNode current) {
      if (current.id == parentId) return current;
      for (final c in current.allDirectChildren) {
        if (c.id == parentId) return c;
        final res = findParent(c);
        if (res != null) return res;
      }
      return null;
    }

    final parent = findParent(root);
    if (parent != null && parent.isScaffold) {
      if (parent.appBar?.id == node.id) return '${node.label} (appBar)';
      if (parent.bottomNavigationBar?.id == node.id)
        return '${node.label} (bottomNavBar)';
      if (parent.floatingActionButton?.id == node.id)
        return '${node.label} (FAB)';
      if (parent.drawer?.id == node.id) return '${node.label} (drawer)';
      if (parent.child?.id == node.id) return '${node.label} (body)';
    }

    return node.label;
  }

  void _showContextMenu(BuildContext context, Offset position) async {
    final node = widget.node;
    final ref = widget.ref;
    final notifier = ref.read(widgetTreeProvider.notifier);
    final activeScreen = ref.read(activeScreenProvider);
    final root = ref.read(widgetTreeProvider)[activeScreen];
    final clipboardNode = ref.read(clipboardProvider);
    final canPaste = clipboardNode != null;

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: const Color(0xFF1E1E35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        if (node.isScaffold) ...[
          PopupMenuItem(
            value: 'add_child',
            enabled: node.child == null,
            child: const _MenuRow(icon: Icons.add, label: 'Add Body'),
          ),
          PopupMenuItem(
            value: 'add_appBar',
            enabled: node.appBar == null,
            child: const _MenuRow(icon: Icons.table_rows, label: 'Add AppBar'),
          ),
          PopupMenuItem(
            value: 'add_bottomNavigationBar',
            enabled: node.bottomNavigationBar == null,
            child: const _MenuRow(
              icon: Icons.horizontal_split,
              label: 'Add BottomNavBar',
            ),
          ),
          PopupMenuItem(
            value: 'add_floatingActionButton',
            enabled: node.floatingActionButton == null,
            child: const _MenuRow(
              icon: Icons.smart_button,
              label: 'Add FloatingActionButton',
            ),
          ),
          PopupMenuItem(
            value: 'add_drawer',
            enabled: node.drawer == null,
            child: const _MenuRow(icon: Icons.menu, label: 'Add Drawer'),
          ),
        ] else if (!node.isLeaf)
          const PopupMenuItem(
            value: 'add_child',
            child: _MenuRow(icon: Icons.add, label: 'Add Child'),
          ),
        const PopupMenuItem(
          value: 'wrap',
          child: _MenuRow(icon: Icons.wrap_text, label: 'Wrap with...'),
        ),
        if (node.allDirectChildren.isNotEmpty)
          const PopupMenuItem(
            value: 'unwrap',
            child: _MenuRow(icon: Icons.layers_clear, label: 'Unwrap'),
          ),
        const PopupMenuItem(
          value: 'duplicate',
          child: _MenuRow(icon: Icons.copy_all, label: 'Duplicate'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'copy',
          child: _MenuRow(icon: Icons.copy, label: 'Copy'),
        ),
        if (canPaste)
          const PopupMenuItem(
            value: 'paste',
            child: _MenuRow(icon: Icons.paste, label: 'Paste'),
          ),
        const PopupMenuDivider(),
        if (root?.id != node.id) ...[
          const PopupMenuItem(
            value: 'move_up',
            child: _MenuRow(icon: Icons.arrow_upward, label: 'Move Up'),
          ),
          const PopupMenuItem(
            value: 'move_down',
            child: _MenuRow(icon: Icons.arrow_downward, label: 'Move Down'),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'rename',
          child: _MenuRow(icon: Icons.edit, label: 'Rename'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Color(0xFFFF6B6B),
          ),
        ),
      ],
    );

    if (result == null || !context.mounted) return;

    switch (result) {
      case 'add_child':
      case 'add_appBar':
      case 'add_bottomNavigationBar':
      case 'add_floatingActionButton':
      case 'add_drawer':
        if (context.mounted) {
          final picked = await showDialog<WidgetType>(
            context: context,
            builder: (_) => const WidgetPickerDialog(),
          );
          if (picked != null) {
            final newNode = WidgetNode(type: picked);
            String? slotName;
            if (result != 'add_child') {
              slotName = result.replaceFirst('add_', '');
            }
            final err = notifier.addChild(node.id, newNode, slotName: slotName);
            if (err != null && context.mounted) {
              _showError(context, err);
            } else {
              ref.read(selectedNodeIdProvider.notifier).state = newNode.id;
            }
          }
        }

      case 'wrap':
        if (context.mounted) {
          final wrapType = await showDialog<WidgetType>(
            context: context,
            builder: (_) => const WrapPickerDialog(),
          );
          if (wrapType != null) {
            final wrapper = WidgetNode(type: wrapType);
            final err = notifier.wrapNode(node.id, wrapper);
            if (err != null && context.mounted) _showError(context, err);
          }
        }

      case 'unwrap':
        notifier.unwrapNode(node.id);

      case 'duplicate':
        final parentId = _findParentId(root, node.id);
        if (parentId != null) {
          notifier.addChild(parentId, node.clone());
        }

      case 'copy':
        ref.read(clipboardProvider.notifier).state = node.clone();

      case 'paste':
        if (clipboardNode != null) {
          final clone = clipboardNode
              .clone(); // Generate new IDs before pasting
          String? targetParentId = node.id;
          bool pasteIntoParent = false;

          if (node.isLeaf) {
            pasteIntoParent = true;
          } else if (node.isSingleChild && node.child != null) {
            pasteIntoParent = true;
          } else if (node.isScaffold &&
              node.child != null &&
              !clone.type.isScaffoldSlotOnly) {
            pasteIntoParent = true;
          }

          if (pasteIntoParent) {
            targetParentId = _findParentId(root, node.id);
          }

          if (targetParentId != null) {
            final err = notifier.addChild(targetParentId, clone);
            if (err != null && context.mounted) {
              _showError(context, err);
            } else {
              ref.read(selectedNodeIdProvider.notifier).state = clone.id;
            }
          }
        }

      case 'move_up':
        notifier.moveNodeUp(node.id);

      case 'move_down':
        notifier.moveNodeDown(node.id);

      case 'rename':
        setState(() => _renaming = true);

      case 'delete':
        notifier.removeNode(node.id);
        if (ref.read(selectedNodeIdProvider) == node.id) {
          ref.read(selectedNodeIdProvider.notifier).state = null;
        }
    }
  }

  String? _findParentId(WidgetNode? root, String childId) {
    if (root == null) return null;
    for (final c in root.allDirectChildren) {
      if (c.id == childId) return root.id;
      final found = _findParentId(c, childId);
      if (found != null) return found;
    }
    return null;
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _RenameField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSubmit;
  final VoidCallback onCancel;

  const _RenameField({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: const TextStyle(fontSize: 12, color: Colors.white),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        border: OutlineInputBorder(),
      ),
      onSubmitted: onSubmit,
      onEditingComplete: () => onSubmit(controller.text),
    );
  }
}

class _EmptyLayers extends StatelessWidget {
  const _EmptyLayers();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.layers_outlined, color: Colors.white24, size: 36),
          SizedBox(height: 8),
          Text(
            'No widgets yet',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'Click + to add a Scaffold',
            style: TextStyle(color: Colors.white24, fontSize: 11),
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
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white70;
    return Row(
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: c)),
      ],
    );
  }
}
