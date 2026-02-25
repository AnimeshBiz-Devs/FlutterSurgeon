import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/tree_provider.dart';

/// Live canvas that renders the actual Flutter widget tree preview.
class CanvasPanel extends ConsumerWidget {
  const CanvasPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeScreen = ref.watch(activeScreenProvider);
    final screens = ref.watch(widgetTreeProvider);
    final root = screens[activeScreen];
    final selectedId = ref.watch(selectedNodeIdProvider);
    final (cw, ch) = ref.watch(canvasSizeProvider);

    return Container(
      color: const Color(0xFF0F0F1E),
      child: Column(
        children: [
          _CanvasToolbar(cw: cw, ch: ch),
          Expanded(
            child: root == null
                ? const _EmptyCanvas()
                : Center(
                    child: InteractiveViewer(
                      minScale: 0.3,
                      maxScale: 3.0,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Container(
                          width: cw,
                          height: ch,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: GestureDetector(
                            // Clicking on canvas background = deselect
                            onTap: () =>
                                ref
                                        .read(selectedNodeIdProvider.notifier)
                                        .state =
                                    null,
                            child: _SelectablePreview(
                              node: root,
                              selectedId: selectedId,
                              onTap: (id) =>
                                  ref
                                          .read(selectedNodeIdProvider.notifier)
                                          .state =
                                      id,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  final double cw;
  final double ch;

  const _CanvasToolbar({required this.cw, required this.ch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
        color: Color(0xFF1A1A2E),
      ),
      child: Row(
        children: [
          const Spacer(),
          Icon(Icons.phone_android, size: 13, color: Colors.white30),
          const SizedBox(width: 4),
          Text(
            '${cw.toInt()} × ${ch.toInt()}',
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _EmptyCanvas extends StatelessWidget {
  const _EmptyCanvas();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 180,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A45), width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_box_outlined, color: Colors.white24, size: 36),
                SizedBox(height: 12),
                Text(
                  'Add a Scaffold\nto get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─ Selectable preview wrapper ─────────────────────────────────────────────────
// Renders the real widget but overlays a selection highlight on tap.

class _SelectablePreview extends StatelessWidget {
  final WidgetNode node;
  final String? selectedId;
  final void Function(String) onTap;

  const _SelectablePreview({
    required this.node,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedId == node.id;
    final preview = _buildPreview(context, node);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap(node.id);
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          preview,
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF7C83FF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, WidgetNode node) {
    // We build a real but non-interactive version of each widget.
    // Children are recursively wrapped with _SelectablePreview.
    switch (node.type) {
      case WidgetType.scaffold:
        return _previewScaffold(context, node);
      case WidgetType.column:
        return _previewColumn(context, node);
      case WidgetType.row:
        return _previewRow(context, node);
      case WidgetType.stack:
        return _previewStack(context, node);
      case WidgetType.container:
        return _previewContainer(context, node);
      case WidgetType.center:
        return Center(child: _childOr(context, node.child));
      case WidgetType.padding:
        return Padding(
          padding: _edgeInsets(node.props['padding']),
          child: _childOr(context, node.child),
        );
      case WidgetType.align:
        return Align(
          alignment: _alignment(node.props['alignment']),
          child: _childOr(context, node.child),
        );
      case WidgetType.expanded:
        return Expanded(
          flex: (node.props['flex'] as int?) ?? 1,
          child: _childOr(context, node.child),
        );
      case WidgetType.sizedBox:
        final w = (node.props['width'] as num?)?.toDouble();
        final h = (node.props['height'] as num?)?.toDouble();
        return SizedBox(
          width: (w == 0 ? null : w),
          height: (h == 0 ? null : h),
          child: _childOr(context, node.child),
        );
      case WidgetType.clipRRect:
        return ClipRRect(
          borderRadius: BorderRadius.circular(
            (node.props['borderRadius'] as num?)?.toDouble() ?? 8,
          ),
          child: _childOr(context, node.child),
        );
      case WidgetType.safeArea:
        return SafeArea(child: _childOr(context, node.child));
      case WidgetType.gestureDetector:
      case WidgetType.inkWell:
        return _childOr(context, node.child);
      case WidgetType.card:
        return Card(
          elevation: (node.props['elevation'] as num?)?.toDouble() ?? 4,
          color: _color(node.props['color']),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              (node.props['borderRadius'] as num?)?.toDouble() ?? 12,
            ),
          ),
          child: _childOr(context, node.child),
        );

      // Display
      case WidgetType.text:
        final p = node.props;
        return Text(
          p['content'] ?? 'Text',
          style: TextStyle(
            fontSize: (p['fontSize'] as num?)?.toDouble() ?? 16,
            fontWeight: p['fontWeight'] == 'bold'
                ? FontWeight.bold
                : FontWeight.normal,
            color: _color(p['color']) ?? Colors.black,
            fontStyle: p['italic'] == true ? FontStyle.italic : null,
          ),
          textAlign: _textAlign(p['textAlign']),
        );
      case WidgetType.icon:
        return Icon(
          Icons.star,
          size: (node.props['size'] as num?)?.toDouble() ?? 24,
          color: _color(node.props['color']),
        );
      case WidgetType.image:
        final p = node.props;
        final src = p['imageSource'] as String? ?? 'network';
        final fitRaw = p['fit'] as String? ?? 'cover';
        BoxFit fit;
        switch (fitRaw) {
          case 'fill':
            fit = BoxFit.fill;
            break;
          case 'contain':
            fit = BoxFit.contain;
            break;
          case 'fitWidth':
            fit = BoxFit.fitWidth;
            break;
          case 'fitHeight':
            fit = BoxFit.fitHeight;
            break;
          case 'none':
            fit = BoxFit.none;
            break;
          case 'scaleDown':
            fit = BoxFit.scaleDown;
            break;
          case 'cover':
          default:
            fit = BoxFit.cover;
        }

        final wMode = p['widthMode'] as String? ?? 'fill';
        final hMode = p['heightMode'] as String? ?? 'fixed';
        final width = wMode == 'fixed'
            ? (p['widthValue'] as num?)?.toDouble()
            : null;
        final height = hMode == 'fixed'
            ? (p['heightValue'] as num?)?.toDouble()
            : null;

        Widget img;
        if (src == 'network') {
          final url = p['url'] as String? ?? '';
          if (url.isEmpty) {
            img = const Icon(Icons.image, color: Colors.white70, size: 32);
          } else {
            img = Image.network(
              url,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white70),
            );
          }
        } else {
          final path = p['assetPath'] as String? ?? '';
          if (path.isEmpty) {
            img = const Icon(Icons.image, color: Colors.white70, size: 32);
          } else {
            img = Image.asset(
              path,
              fit: fit,
              width: width,
              height: height,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image, color: Colors.white70),
            );
          }
        }

        return Container(
          width: wMode == 'fill' ? double.infinity : width,
          height: hMode == 'fill' ? double.infinity : height,
          color: Colors.grey[800],
          child: img,
        );
      case WidgetType.divider:
        return Divider(
          height: (node.props['height'] as num?)?.toDouble() ?? 1,
          thickness: (node.props['thickness'] as num?)?.toDouble() ?? 1,
          color: _color(node.props['color']) ?? Colors.grey,
        );
      case WidgetType.circleAvatar:
        return CircleAvatar(
          radius: (node.props['radius'] as num?)?.toDouble() ?? 24,
          backgroundColor: _color(node.props['backgroundColor']) ?? Colors.grey,
          child: Text(
            node.props['initials'] ?? '',
            style: const TextStyle(color: Colors.white),
          ),
        );

      // Buttons
      case WidgetType.elevatedButton:
        return ElevatedButton(
          onPressed: null,
          child: _childOr(context, node.child),
        );
      case WidgetType.textButton:
        return TextButton(
          onPressed: null,
          child: _childOr(context, node.child),
        );
      case WidgetType.outlinedButton:
        return OutlinedButton(
          onPressed: null,
          child: _childOr(context, node.child),
        );
      case WidgetType.iconButton:
        return IconButton(
          onPressed: null,
          icon: Icon(
            Icons.favorite,
            size: (node.props['iconSize'] as num?)?.toDouble() ?? 24,
          ),
        );
      case WidgetType.textField:
        return TextField(
          decoration: InputDecoration(
            hintText: node.props['hintText'] ?? 'Enter text...',
          ),
          enabled: false,
        );

      // Navigation
      case WidgetType.appBar:
        return AppBar(
          title: Text(node.props['title'] ?? 'Title'),
          centerTitle: node.props['centerTitle'] == true,
          backgroundColor: _color(node.props['backgroundColor']),
          elevation: (node.props['elevation'] as num?)?.toDouble() ?? 0,
        );
      case WidgetType.bottomNavigationBar:
        final items =
            (node.props['items'] as List<dynamic>? ?? ['Home', 'Profile']);
        return BottomNavigationBar(
          items: items
              .map(
                (i) => BottomNavigationBarItem(
                  icon: const Icon(Icons.label),
                  label: i.toString(),
                ),
              )
              .toList(),
          currentIndex: (node.props['currentIndex'] as int?) ?? 0,
        );
      case WidgetType.floatingActionButton:
        return FloatingActionButton(
          onPressed: null,
          backgroundColor: _color(node.props['backgroundColor']),
          child: Icon(Icons.add),
        );
      case WidgetType.drawer:
        return Drawer(child: _childOr(context, node.child));

      // Decoration
      case WidgetType.listTile:
        return ListTile(
          title: Text(node.props['title'] ?? 'List Item'),
          subtitle: (node.props['subtitle'] as String? ?? '').isNotEmpty
              ? Text(node.props['subtitle'])
              : null,
          leading: Icon(Icons.label),
          trailing: Icon(Icons.chevron_right),
        );
      case WidgetType.chip:
        return Chip(label: Text(node.props['label'] ?? 'Chip'));
      case WidgetType.wrap:
        return Wrap(
          spacing: (node.props['spacing'] as num?)?.toDouble() ?? 0,
          runSpacing: (node.props['runSpacing'] as num?)?.toDouble() ?? 0,
          children: node.children.map((c) => _child(context, c)).toList(),
        );
      case WidgetType.listView:
        return Column(
          children: node.children.map((c) => _child(context, c)).toList(),
        );
    }
  }

  Widget _previewScaffold(BuildContext context, WidgetNode node) {
    return Scaffold(
      backgroundColor: _color(node.props['backgroundColor']) ?? Colors.white,
      appBar: node.appBar != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: _child(context, node.appBar!),
            )
          : null,
      body: node.child != null ? _child(context, node.child!) : null,
      bottomNavigationBar: node.bottomNavigationBar != null
          ? _child(context, node.bottomNavigationBar!)
          : null,
      floatingActionButton: node.floatingActionButton != null
          ? _child(context, node.floatingActionButton!)
          : null,
      drawer: node.drawer != null ? _child(context, node.drawer!) : null,
    );
  }

  Widget _previewColumn(BuildContext context, WidgetNode node) {
    final p = node.props;
    return Column(
      mainAxisAlignment: _mainAxis(p['mainAxisAlignment']),
      crossAxisAlignment: _crossAxis(p['crossAxisAlignment']),
      mainAxisSize: p['mainAxisSize'] == 'min'
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: node.children.map((c) => _child(context, c)).toList(),
    );
  }

  Widget _previewRow(BuildContext context, WidgetNode node) {
    final p = node.props;
    return Row(
      mainAxisAlignment: _mainAxis(p['mainAxisAlignment']),
      crossAxisAlignment: _crossAxis(p['crossAxisAlignment']),
      mainAxisSize: p['mainAxisSize'] == 'min'
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: node.children.map((c) => _child(context, c)).toList(),
    );
  }

  Widget _previewStack(BuildContext context, WidgetNode node) {
    return Stack(
      alignment: _alignment(node.props['alignment']),
      children: node.children.map((c) => _child(context, c)).toList(),
    );
  }

  Widget _previewContainer(BuildContext context, WidgetNode node) {
    final p = node.props;
    final wMode = p['widthMode'] as String? ?? 'wrap';
    final hMode = p['heightMode'] as String? ?? 'wrap';

    Color? bgColor = _color(p['color']);
    BoxDecoration? dec;
    if (bgColor != null ||
        (p['borderRadius'] as num? ?? 0) > 0 ||
        p['useGradient'] == true) {
      Gradient? grad;
      if (p['useGradient'] == true) {
        final c1 = _color(p['gradientColor1']) ?? const Color(0xFFFF5555);
        final c2 = _color(p['gradientColor2']) ?? const Color(0xFF5555FF);
        final begin = _alignment(p['gradientBegin'] ?? 'topLeft');
        final end = _alignment(p['gradientEnd'] ?? 'bottomRight');
        grad = LinearGradient(begin: begin, end: end, colors: [c1, c2]);
      }

      dec = BoxDecoration(
        color: p['useGradient'] == true ? null : bgColor,
        gradient: grad,
        borderRadius: BorderRadius.circular(
          (p['borderRadius'] as num?)?.toDouble() ?? 0,
        ),
        border: p['borderColor'] != null
            ? Border.all(
                color: _color(p['borderColor']) ?? Colors.transparent,
                width: (p['borderWidth'] as num?)?.toDouble() ?? 1,
              )
            : null,
      );
    }

    return Container(
      width: wMode == 'fill'
          ? double.infinity
          : (wMode == 'fixed' ? (p['widthValue'] as num?)?.toDouble() : null),
      height: hMode == 'fill'
          ? double.infinity
          : (hMode == 'fixed' ? (p['heightValue'] as num?)?.toDouble() : null),
      padding: _edgeInsets(p['padding']),
      margin: _edgeInsets(p['margin']),
      decoration: dec,
      child: _childOr(context, node.child),
    );
  }

  Widget _child(BuildContext context, WidgetNode c) {
    return _SelectablePreview(node: c, selectedId: selectedId, onTap: onTap);
  }

  /// Returns a non-null Widget — falls back to SizedBox() if child is null.
  Widget _childOr(BuildContext context, WidgetNode? c) {
    if (c == null) return const SizedBox();
    return _child(context, c);
  }

  // ─ Converters ─────────────────────────────────────────────────────────────
  EdgeInsets _edgeInsets(dynamic v) {
    if (v is! Map) return EdgeInsets.zero;
    return EdgeInsets.fromLTRB(
      (v['left'] as num?)?.toDouble() ?? 0,
      (v['top'] as num?)?.toDouble() ?? 0,
      (v['right'] as num?)?.toDouble() ?? 0,
      (v['bottom'] as num?)?.toDouble() ?? 0,
    );
  }

  Alignment _alignment(dynamic v) {
    const map = {
      'topLeft': Alignment.topLeft,
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'centerLeft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerRight': Alignment.centerRight,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    };
    return map[v] ?? Alignment.topLeft;
  }

  MainAxisAlignment _mainAxis(dynamic v) {
    const map = {
      'start': MainAxisAlignment.start,
      'center': MainAxisAlignment.center,
      'end': MainAxisAlignment.end,
      'spaceBetween': MainAxisAlignment.spaceBetween,
      'spaceAround': MainAxisAlignment.spaceAround,
      'spaceEvenly': MainAxisAlignment.spaceEvenly,
    };
    return map[v] ?? MainAxisAlignment.start;
  }

  CrossAxisAlignment _crossAxis(dynamic v) {
    const map = {
      'start': CrossAxisAlignment.start,
      'center': CrossAxisAlignment.center,
      'end': CrossAxisAlignment.end,
      'stretch': CrossAxisAlignment.stretch,
    };
    return map[v] ?? CrossAxisAlignment.center;
  }

  TextAlign? _textAlign(dynamic v) {
    const map = {
      'left': TextAlign.left,
      'center': TextAlign.center,
      'right': TextAlign.right,
      'justify': TextAlign.justify,
    };
    return map[v];
  }

  Color? _color(dynamic hex) {
    if (hex == null || hex == '#00000000') return null;
    try {
      final h = (hex as String).replaceFirst('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return null;
  }
}
