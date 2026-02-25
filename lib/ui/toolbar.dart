import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;

import '../models/index.dart';
import '../providers/tree_provider.dart';
import '../core/code_generator.dart';

class AppToolbar extends ConsumerWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(widgetTreeProvider.notifier);
    final screens = ref.watch(widgetTreeProvider);
    final activeScreen = ref.watch(activeScreenProvider);
    final showCode = ref.watch(showCodePanelProvider);

    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF14142A),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Row(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C83FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'FS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FlutterSurgeon',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const VerticalDivider(
            color: Color(0xFF2A2A45),
            width: 1,
            indent: 8,
            endIndent: 8,
          ),

          // Screen name edit
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _ScreenNameField(screenName: activeScreen),
            ),
          ),

          const VerticalDivider(
            color: Color(0xFF2A2A45),
            width: 1,
            indent: 8,
            endIndent: 8,
          ),

          // Undo / Redo
          _ToolbarBtn(
            icon: Icons.undo,
            tooltip: 'Undo (Ctrl+Z)',
            onPressed: notifier.canUndo ? () => notifier.undo() : null,
          ),
          _ToolbarBtn(
            icon: Icons.redo,
            tooltip: 'Redo (Ctrl+Shift+Z)',
            onPressed: notifier.canRedo ? () => notifier.redo() : null,
          ),

          const VerticalDivider(
            color: Color(0xFF2A2A45),
            width: 1,
            indent: 8,
            endIndent: 8,
          ),

          // New layout
          _ToolbarBtn(
            icon: Icons.add_box_outlined,
            tooltip: 'New Screen',
            label: 'New',
            onPressed: () => _confirmNew(context, ref),
          ),

          // Save
          _ToolbarBtn(
            icon: Icons.save_outlined,
            tooltip: 'Save (.fsurgery)',
            label: 'Save',
            onPressed: screens.isNotEmpty
                ? () => _saveProject(context, ref, activeScreen)
                : null,
          ),

          // Open
          _ToolbarBtn(
            icon: Icons.folder_open_outlined,
            tooltip: 'Open (.fsurgery)',
            label: 'Open',
            onPressed: () => _openProject(context, ref),
          ),

          const Spacer(),

          // Code toggle
          _ToolbarToggle(
            icon: Icons.code,
            label: 'Code',
            active: showCode,
            onToggle: () =>
                ref.read(showCodePanelProvider.notifier).state = !showCode,
          ),

          const SizedBox(width: 8),

          // Export code
          _ToolbarBtn(
            icon: Icons.download_outlined,
            tooltip: 'Export Code (.dart)',
            label: 'Export',
            onPressed: screens.isNotEmpty
                ? () => _exportCode(context, ref, activeScreen)
                : null,
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  void _confirmNew(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E35),
        title: const Text('New Screen', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear the current screen. Continue?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FF),
            ),
            onPressed: () {
              final newName =
                  'Screen${(ref.read(widgetTreeProvider).length + 1)}';
              ref.read(widgetTreeProvider.notifier).addScreen(newName);
              ref.read(activeScreenProvider.notifier).state = newName;
              ref.read(selectedNodeIdProvider.notifier).state = null;
              Navigator.pop(context);
            },
            child: const Text('New Screen'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCode(
    BuildContext context,
    WidgetRef ref,
    String screenName,
  ) async {
    final screens = ref.read(widgetTreeProvider);
    if (screens.isEmpty) return;
    String code = '';
    try {
      code = CodeGenerator().generateProject(screens, screenName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating code: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (kIsWeb) {
      final bytes = utf8.encode(code);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'main.dart';
      html.document.body!.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export FlutterSurgeon Code',
        fileName: 'main.dart',
        type: FileType.custom,
        allowedExtensions: ['dart'],
      );
      if (path != null) {
        await File(path).writeAsString(code);
      } else {
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code exported!'),
          backgroundColor: Color(0xFF4ECDC4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveProject(
    BuildContext context,
    WidgetRef ref,
    String screenName,
  ) async {
    final screens = ref.read(widgetTreeProvider);
    if (screens.isEmpty) return;
    final project = ProjectModel(
      screenName: screenName,
      screens: screens,
      canvasWidth: ref.read(canvasSizeProvider).$1,
      canvasHeight: ref.read(canvasSizeProvider).$2,
    );
    final jsonStr = jsonEncode(project.toJson());

    if (kIsWeb) {
      final bytes = utf8.encode(jsonStr);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '$screenName.fsurgery';
      html.document.body!.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save FlutterSurgeon Project',
        fileName: '$screenName.fsurgery',
        type: FileType.custom,
        allowedExtensions: ['fsurgery', 'json'],
      );
      if (path != null) {
        await File(path).writeAsString(jsonStr);
      } else {
        return;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project saved!'),
          backgroundColor: Color(0xFF4ECDC4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openProject(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['fsurgery', 'json'],
      dialogTitle: 'Open FlutterSurgeon Project',
    );
    if (result == null || result.files.isEmpty) return;

    try {
      String jsonString;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) throw Exception('No file payload received.');
        jsonString = utf8.decode(bytes);
      } else {
        final file = File(result.files.first.path!);
        jsonString = await file.readAsString();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final project = ProjectModel.fromJson(json);
      ref.read(widgetTreeProvider.notifier).loadProject(project);
      ref.read(activeScreenProvider.notifier).state = project.screenName;
      ref.read(canvasSizeProvider.notifier).state = (
        project.canvasWidth,
        project.canvasHeight,
      );
      ref.read(selectedNodeIdProvider.notifier).state = null;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project loaded!'),
            backgroundColor: Color(0xFF7C83FF),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _ScreenNameField extends ConsumerStatefulWidget {
  final String screenName;
  const _ScreenNameField({required this.screenName});

  @override
  ConsumerState<_ScreenNameField> createState() => _ScreenNameFieldState();
}

class _ScreenNameFieldState extends ConsumerState<_ScreenNameField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.screenName);
  }

  @override
  void didUpdateWidget(_ScreenNameField old) {
    super.didUpdateWidget(old);
    if (old.screenName != widget.screenName &&
        _ctrl.text != widget.screenName) {
      _ctrl.text = widget.screenName;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFF2A2A45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: Color(0xFF7C83FF)),
        ),
        filled: true,
        fillColor: Color(0xFF0F0F22),
      ),
      onSubmitted: (v) {
        if (v.isEmpty) return;
        final oldName = ref.read(activeScreenProvider);
        if (oldName == v) return;
        ref.read(widgetTreeProvider.notifier).renameScreen(oldName, v);
        ref.read(activeScreenProvider.notifier).state = v;
      },
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String? label;
  final VoidCallback? onPressed;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null ? Colors.white24 : Colors.white60;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(label!, style: TextStyle(color: color, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onToggle;

  const _ToolbarToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7C83FF).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? const Color(0xFF7C83FF) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: active ? const Color(0xFF7C83FF) : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF7C83FF) : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
