import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable building blocks for the Properties Panel.
// All widgets are intentionally lightweight — no Riverpod here, props come from parent.

// ─ Layout helpers ────────────────────────────────────────────────────────────

class PropGroup extends StatelessWidget {
  final List<Widget> children;
  const PropGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w),
          )
          .toList(),
    );
  }
}

class PropRow extends StatelessWidget {
  final List<Widget> children;
  const PropRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 6)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

class PropSectionLabel extends StatelessWidget {
  final String label;
  const PropSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white30,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─ Input atoms ───────────────────────────────────────────────────────────────

class PropTextField extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChange;

  const PropTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  State<PropTextField> createState() => _PropTextFieldState();
}

class _PropTextFieldState extends State<PropTextField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PropTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.label,
      child: TextField(
        controller: _ctrl,
        style: _inputStyle,
        decoration: _inputDec,
        onSubmitted: widget.onChange,
        onEditingComplete: () => widget.onChange(_ctrl.text),
      ),
    );
  }
}

class PropTextArea extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChange;

  const PropTextArea({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  State<PropTextArea> createState() => _PropTextAreaState();
}

class _PropTextAreaState extends State<PropTextArea> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PropTextArea old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.label,
      child: TextField(
        controller: _ctrl,
        style: _inputStyle,
        decoration: _inputDec,
        maxLines: 3,
        onChanged: widget.onChange,
      ),
    );
  }
}

class PropNumber extends StatefulWidget {
  final String label;
  final double value;
  final void Function(double) onChange;

  const PropNumber({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  State<PropNumber> createState() => _PropNumberState();
}

class _PropNumberState extends State<PropNumber> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(PropNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final newText = _fmt(widget.value);
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.truncate().toString() : v.toString();

  void _submit() {
    final parsed = double.tryParse(_ctrl.text);
    if (parsed != null) widget.onChange(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.label,
      child: TextField(
        controller: _ctrl,
        style: _inputStyle,
        decoration: _inputDec,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        onSubmitted: (_) => _submit(),
        onEditingComplete: _submit,
      ),
    );
  }
}

class PropDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final void Function(String) onChange;

  const PropDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: label,
      child: DropdownButtonFormField<String>(
        value: options.contains(value) ? value : options.first,
        items: options
            .map(
              (o) => DropdownMenuItem(
                value: o,
                child: Text(o, style: _inputStyle),
              ),
            )
            .toList(),
        onChanged: (v) => onChange(v!),
        dropdownColor: const Color(0xFF252540),
        decoration: _inputDec,
        style: _inputStyle,
        isDense: true,
        isExpanded: true,
      ),
    );
  }
}

class PropToggle extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChange;

  const PropToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        Transform.scale(
          scale: 0.75,
          child: Switch(
            value: value,
            onChanged: onChange,
            activeColor: const Color(0xFF7C83FF),
          ),
        ),
      ],
    );
  }
}

class PropColor extends StatefulWidget {
  final String label;
  final String value; // hex #RRGGBB or #AARRGGBB
  final void Function(String) onChange;

  const PropColor({
    super.key,
    required this.label,
    required this.value,
    required this.onChange,
  });

  @override
  State<PropColor> createState() => _PropColorState();
}

class _PropColorState extends State<PropColor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PropColor old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _parse(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final color = _parse(widget.value);
    return _LabeledField(
      label: widget.label,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showPicker(context),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: _inputStyle,
              decoration: _inputDec,
              onSubmitted: (v) => widget.onChange(v),
              onEditingComplete: () => widget.onChange(_ctrl.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    // Simple color grid picker — no external package needed
    final colors = [
      '#FFFFFF',
      '#000000',
      '#FF6B6B',
      '#FFE66D',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#7C83FF',
      '#F8A5C2',
      '#FDA7DF',
      '#D980FA',
      '#9980FA',
      '#1289A7',
      '#12CBC4',
      '#A3CB38',
      '#009432',
      '#ED4C67',
      '#F79F1F',
      '#EE5A24',
      '#EA2027',
      '#0652DD',
      '#1B1464',
      '#6F1E51',
      '#182C61',
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E35),
        title: const Text(
          'Pick Color',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: SizedBox(
          width: 240,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((hex) {
              return GestureDetector(
                onTap: () {
                  widget.onChange(hex);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _parse(hex),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: hex == widget.value
                          ? Colors.white
                          : Colors.white24,
                      width: hex == widget.value ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─ Internal ──────────────────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
        const SizedBox(height: 3),
        child,
      ],
    );
  }
}

const _inputStyle = TextStyle(color: Colors.white, fontSize: 12);

const _inputDec = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  filled: true,
  fillColor: Color(0xFF252540),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
    borderSide: BorderSide(color: Color(0xFF3A3A5C)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
    borderSide: BorderSide(color: Color(0xFF3A3A5C)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(5)),
    borderSide: BorderSide(color: Color(0xFF7C83FF)),
  ),
);
