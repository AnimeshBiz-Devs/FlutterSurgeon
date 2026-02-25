import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/code_generator.dart';
import '../providers/tree_provider.dart';

class CodePanel extends ConsumerWidget {
  const CodePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = ref.watch(activeScreenProvider);
    final screens = ref.watch(widgetTreeProvider);

    String code = '';
    if (screens.isNotEmpty) {
      try {
        code = CodeGenerator().generateProject(screens, activeScreen);
      } catch (e) {
        code = '// Error generating code: $e';
      }
    } else {
      code = '// Add a Scaffold to get started.';
    }

    return Container(
      color: const Color(0xFF0D0D1A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF12122A),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 14, color: Color(0xFF7C83FF)),
                const SizedBox(width: 6),
                Text(
                  'main.dart',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _CopyButton(code: code),
              ],
            ),
          ),
          // Code view
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono, Consolas, monospace',
                  fontSize: 12,
                  color: Color(0xFFCDD0FF),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String code;
  const _CopyButton({required this.code});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.code));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 13,
        color: _copied ? const Color(0xFF4ECDC4) : const Color(0xFF7C83FF),
      ),
      label: Text(
        _copied ? 'Copied!' : 'Copy',
        style: TextStyle(
          fontSize: 11,
          color: _copied ? const Color(0xFF4ECDC4) : const Color(0xFF7C83FF),
        ),
      ),
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
    );
  }
}
