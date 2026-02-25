import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/tree_provider.dart';
import 'prop_widgets.dart';

class PropertiesPanel extends ConsumerWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedNodeIdProvider);
    final activeScreen = ref.watch(activeScreenProvider);
    final screens = ref.watch(widgetTreeProvider);
    final root = screens[activeScreen];

    WidgetNode? node;
    if (selectedId != null && root != null) {
      node = _findById(root, selectedId);
    }

    return Container(
      width: 264,
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: node != null ? node.type.displayName : 'Properties',
          ),
          if (node == null)
            const Expanded(child: _EmptyProps())
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPropsFor(node, ref),
                    if (_isInteractive(node.type)) ...[
                      const SizedBox(height: 16),
                      _NavigationActionProps(node: node),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropsFor(WidgetNode node, WidgetRef ref) {
    void setProp(String key, dynamic value) {
      ref.read(widgetTreeProvider.notifier).updateProps(node.id, key, value);
    }

    switch (node.type) {
      case WidgetType.text:
        return _TextProps(node: node, setProp: setProp);
      case WidgetType.container:
        return _ContainerProps(node: node, setProp: setProp);
      case WidgetType.column:
      case WidgetType.row:
        return _AxisProps(node: node, setProp: setProp);
      case WidgetType.sizedBox:
        return _SizedBoxProps(node: node, setProp: setProp);
      case WidgetType.padding:
        return _EdgeInsetsProps(
          label: 'Padding',
          propKey: 'padding',
          node: node,
          setProp: setProp,
        );
      case WidgetType.expanded:
        return _ExpandedProps(node: node, setProp: setProp);
      case WidgetType.appBar:
        return _AppBarProps(node: node, setProp: setProp);
      case WidgetType.scaffold:
        return _ScaffoldProps(node: node, setProp: setProp);
      case WidgetType.icon:
        return _IconProps(node: node, setProp: setProp);
      case WidgetType.divider:
        return _DividerProps(node: node, setProp: setProp);
      case WidgetType.clipRRect:
        return _RadiusProps(node: node, setProp: setProp);
      case WidgetType.card:
        return _CardProps(node: node, setProp: setProp);
      case WidgetType.image:
        return _ImageProps(node: node, setProp: setProp);
      default:
        // Generic: show raw props as key-value list
        return _GenericProps(node: node, setProp: setProp);
    }
  }

  WidgetNode? _findById(WidgetNode node, String id) {
    if (node.id == id) return node;
    for (final c in node.allDirectChildren) {
      final found = _findById(c, id);
      if (found != null) return found;
    }
    return null;
  }

  bool _isInteractive(WidgetType type) {
    return const {
      WidgetType.gestureDetector,
      WidgetType.inkWell,
      WidgetType.elevatedButton,
      WidgetType.textButton,
      WidgetType.outlinedButton,
      WidgetType.iconButton,
      WidgetType.floatingActionButton,
      WidgetType.listTile,
      WidgetType.bottomNavigationBar,
    }.contains(type);
  }
}

// ─── Individual prop editors ─────────────────────────────────────────────────

class _NavigationActionProps extends ConsumerWidget {
  final WidgetNode node;
  const _NavigationActionProps({required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screens = ref.watch(widgetTreeProvider).keys.toList();
    final p = node.props;
    final currentTarget = p['onTapNavigateTo'] as String?;

    return PropGroup(
      children: [
        const PropSectionLabel('Action'),
        PropDropdown(
          label: 'Navigate To',
          value: currentTarget ?? 'None',
          options: ['None', ...screens],
          onChange: (v) {
            ref
                .read(widgetTreeProvider.notifier)
                .updateProps(
                  node.id,
                  'onTapNavigateTo',
                  v == 'None' ? null : v,
                );
          },
        ),
      ],
    );
  }
}

class _TextProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _TextProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropTextArea(
          label: 'Content',
          value: p['content'] ?? '',
          onChange: (v) => setProp('content', v),
        ),
        PropRow(
          children: [
            PropNumber(
              label: 'Font size',
              value: (p['fontSize'] as num?)?.toDouble() ?? 16,
              onChange: (v) => setProp('fontSize', v),
            ),
            PropDropdown(
              label: 'Weight',
              value: p['fontWeight'] ?? 'normal',
              options: const [
                'normal',
                'bold',
                'w300',
                'w400',
                'w500',
                'w600',
                'w700',
                'w800',
                'w900',
              ],
              onChange: (v) => setProp('fontWeight', v),
            ),
          ],
        ),
        PropColor(
          label: 'Color',
          value: p['color'] ?? '#FFFFFF',
          onChange: (v) => setProp('color', v),
        ),
        PropDropdown(
          label: 'Text Align',
          value: p['textAlign'] ?? 'left',
          options: const ['left', 'center', 'right', 'justify'],
          onChange: (v) => setProp('textAlign', v),
        ),
        PropToggle(
          label: 'Italic',
          value: p['italic'] == true,
          onChange: (v) => setProp('italic', v),
        ),
      ],
    );
  }
}

class _ContainerProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _ContainerProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        const PropSectionLabel('Size'),
        PropRow(
          children: [
            PropDropdown(
              label: 'Width',
              value: p['widthMode'] ?? 'wrap',
              options: const ['wrap', 'fill', 'fixed'],
              onChange: (v) => setProp('widthMode', v),
            ),
            if (p['widthMode'] == 'fixed')
              PropNumber(
                label: 'W px',
                value: (p['widthValue'] as num?)?.toDouble() ?? 100,
                onChange: (v) => setProp('widthValue', v),
              ),
          ],
        ),
        PropRow(
          children: [
            PropDropdown(
              label: 'Height',
              value: p['heightMode'] ?? 'wrap',
              options: const ['wrap', 'fill', 'fixed'],
              onChange: (v) => setProp('heightMode', v),
            ),
            if (p['heightMode'] == 'fixed')
              PropNumber(
                label: 'H px',
                value: (p['heightValue'] as num?)?.toDouble() ?? 100,
                onChange: (v) => setProp('heightValue', v),
              ),
          ],
        ),
        const PropSectionLabel('Background'),
        PropColor(
          label: 'Color',
          value: p['color'] ?? '#00000000',
          onChange: (v) => setProp('color', v == '#00000000' ? null : v),
        ),
        PropToggle(
          label: 'Use Gradient',
          value: p['useGradient'] == true,
          onChange: (v) => setProp('useGradient', v),
        ),
        if (p['useGradient'] == true) ...[
          PropRow(
            children: [
              PropColor(
                label: 'Color 1',
                value: p['gradientColor1'] ?? '#FF5555',
                onChange: (v) => setProp('gradientColor1', v),
              ),
              PropColor(
                label: 'Color 2',
                value: p['gradientColor2'] ?? '#5555FF',
                onChange: (v) => setProp('gradientColor2', v),
              ),
            ],
          ),
          PropRow(
            children: [
              PropDropdown(
                label: 'Begin',
                value: p['gradientBegin'] ?? 'topLeft',
                options: const [
                  'topLeft',
                  'topCenter',
                  'topRight',
                  'centerLeft',
                  'center',
                  'centerRight',
                  'bottomLeft',
                  'bottomCenter',
                  'bottomRight',
                ],
                onChange: (v) => setProp('gradientBegin', v),
              ),
              PropDropdown(
                label: 'End',
                value: p['gradientEnd'] ?? 'bottomRight',
                options: const [
                  'topLeft',
                  'topCenter',
                  'topRight',
                  'centerLeft',
                  'center',
                  'centerRight',
                  'bottomLeft',
                  'bottomCenter',
                  'bottomRight',
                ],
                onChange: (v) => setProp('gradientEnd', v),
              ),
            ],
          ),
        ],
        const PropSectionLabel('Border'),
        PropNumber(
          label: 'Radius',
          value: (p['borderRadius'] as num?)?.toDouble() ?? 0,
          onChange: (v) => setProp('borderRadius', v),
        ),
        PropColor(
          label: 'Border color',
          value: p['borderColor'] ?? '#00000000',
          onChange: (v) => setProp('borderColor', v == '#00000000' ? null : v),
        ),
        PropNumber(
          label: 'Border width',
          value: (p['borderWidth'] as num?)?.toDouble() ?? 0,
          onChange: (v) => setProp('borderWidth', v),
        ),
        const PropSectionLabel('Padding'),
        _EdgeInsetEditor(propKey: 'padding', node: node, setProp: setProp),
        const PropSectionLabel('Margin'),
        _EdgeInsetEditor(propKey: 'margin', node: node, setProp: setProp),
      ],
    );
  }
}

class _AxisProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _AxisProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropDropdown(
          label: 'Main Axis Align',
          value: p['mainAxisAlignment'] ?? 'start',
          options: const [
            'start',
            'center',
            'end',
            'spaceBetween',
            'spaceAround',
            'spaceEvenly',
          ],
          onChange: (v) => setProp('mainAxisAlignment', v),
        ),
        PropDropdown(
          label: 'Cross Axis Align',
          value: p['crossAxisAlignment'] ?? 'center',
          options: const ['start', 'center', 'end', 'stretch', 'baseline'],
          onChange: (v) => setProp('crossAxisAlignment', v),
        ),
        PropDropdown(
          label: 'Main Axis Size',
          value: p['mainAxisSize'] ?? 'max',
          options: const ['max', 'min'],
          onChange: (v) => setProp('mainAxisSize', v),
        ),
      ],
    );
  }
}

class _SizedBoxProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _SizedBoxProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropNumber(
          label: 'Width',
          value: (p['width'] as num?)?.toDouble() ?? 0,
          onChange: (v) => setProp('width', v),
        ),
        PropNumber(
          label: 'Height',
          value: (p['height'] as num?)?.toDouble() ?? 0,
          onChange: (v) => setProp('height', v),
        ),
      ],
    );
  }
}

class _ExpandedProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _ExpandedProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    return PropGroup(
      children: [
        PropNumber(
          label: 'Flex',
          value: (node.props['flex'] as num?)?.toDouble() ?? 1,
          onChange: (v) => setProp('flex', v.toInt()),
        ),
      ],
    );
  }
}

class _EdgeInsetsProps extends StatelessWidget {
  final String label;
  final String propKey;
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _EdgeInsetsProps({
    required this.label,
    required this.propKey,
    required this.node,
    required this.setProp,
  });

  @override
  Widget build(BuildContext context) {
    return PropGroup(
      children: [
        PropSectionLabel(label),
        _EdgeInsetEditor(propKey: propKey, node: node, setProp: setProp),
      ],
    );
  }
}

class _AppBarProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _AppBarProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropTextField(
          label: 'Title',
          value: p['title'] ?? 'Title',
          onChange: (v) => setProp('title', v),
        ),
        PropToggle(
          label: 'Center Title',
          value: p['centerTitle'] == true,
          onChange: (v) => setProp('centerTitle', v),
        ),
        PropNumber(
          label: 'Elevation',
          value: (p['elevation'] as num?)?.toDouble() ?? 0,
          onChange: (v) => setProp('elevation', v),
        ),
        PropColor(
          label: 'Background',
          value: p['backgroundColor'] ?? '#00000000',
          onChange: (v) =>
              setProp('backgroundColor', v == '#00000000' ? null : v),
        ),
        PropColor(
          label: 'Foreground',
          value: p['foregroundColor'] ?? '#FFFFFF',
          onChange: (v) => setProp('foregroundColor', v),
        ),
      ],
    );
  }
}

class _ScaffoldProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _ScaffoldProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropColor(
          label: 'Background',
          value: p['backgroundColor'] ?? '#00000000',
          onChange: (v) =>
              setProp('backgroundColor', v == '#00000000' ? null : v),
        ),
        const PropSectionLabel('Slots'),
        const Text(
          'Right-click a slot widget in\nLayers to set as Scaffold slot.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}

class _IconProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _IconProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropTextField(
          label: 'Icon name',
          value: p['iconName'] ?? 'star',
          onChange: (v) => setProp('iconName', v),
        ),
        PropNumber(
          label: 'Size',
          value: (p['size'] as num?)?.toDouble() ?? 24,
          onChange: (v) => setProp('size', v),
        ),
        PropColor(
          label: 'Color',
          value: p['color'] ?? '#FFFFFF',
          onChange: (v) => setProp('color', v),
        ),
      ],
    );
  }
}

class _DividerProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _DividerProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropNumber(
          label: 'Height',
          value: (p['height'] as num?)?.toDouble() ?? 1,
          onChange: (v) => setProp('height', v),
        ),
        PropNumber(
          label: 'Thickness',
          value: (p['thickness'] as num?)?.toDouble() ?? 1,
          onChange: (v) => setProp('thickness', v),
        ),
        PropColor(
          label: 'Color',
          value: p['color'] ?? '#444444',
          onChange: (v) => setProp('color', v),
        ),
      ],
    );
  }
}

class _RadiusProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _RadiusProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    return PropGroup(
      children: [
        PropNumber(
          label: 'Border Radius',
          value: (node.props['borderRadius'] as num?)?.toDouble() ?? 8,
          onChange: (v) => setProp('borderRadius', v),
        ),
      ],
    );
  }
}

class _CardProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _CardProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropNumber(
          label: 'Elevation',
          value: (p['elevation'] as num?)?.toDouble() ?? 4,
          onChange: (v) => setProp('elevation', v),
        ),
        PropNumber(
          label: 'Radius',
          value: (p['borderRadius'] as num?)?.toDouble() ?? 12,
          onChange: (v) => setProp('borderRadius', v),
        ),
        PropColor(
          label: 'Color',
          value: p['color'] ?? '#00000000',
          onChange: (v) => setProp('color', v == '#00000000' ? null : v),
        ),
      ],
    );
  }
}

class _GenericProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _GenericProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final entries = node.props.toJson().entries.toList();
    return PropGroup(
      children: entries.map((e) {
        final v = e.value;
        if (v is bool) {
          return PropToggle(
            label: e.key,
            value: v,
            onChange: (nv) => setProp(e.key, nv),
          );
        } else if (v is num) {
          return PropNumber(
            label: e.key,
            value: v.toDouble(),
            onChange: (nv) => setProp(e.key, nv),
          );
        } else if (v is String) {
          return PropTextField(
            label: e.key,
            value: v,
            onChange: (nv) => setProp(e.key, nv),
          );
        }
        return const SizedBox();
      }).toList(),
    );
  }
}

class _EdgeInsetEditor extends StatelessWidget {
  final String propKey;
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _EdgeInsetEditor({
    required this.propKey,
    required this.node,
    required this.setProp,
  });

  Map<String, double> _getMap() {
    final v = node.props[propKey];
    if (v is Map) {
      return {
        'top': (v['top'] as num?)?.toDouble() ?? 0,
        'right': (v['right'] as num?)?.toDouble() ?? 0,
        'bottom': (v['bottom'] as num?)?.toDouble() ?? 0,
        'left': (v['left'] as num?)?.toDouble() ?? 0,
      };
    }
    return {'top': 0, 'right': 0, 'bottom': 0, 'left': 0};
  }

  void _set(String side, double val) {
    final m = _getMap();
    m[side] = val;
    setProp(propKey, m);
  }

  @override
  Widget build(BuildContext context) {
    final m = _getMap();
    return Column(
      children: [
        PropRow(
          children: [
            PropNumber(
              label: 'Top',
              value: m['top']!,
              onChange: (v) => _set('top', v),
            ),
            PropNumber(
              label: 'Bottom',
              value: m['bottom']!,
              onChange: (v) => _set('bottom', v),
            ),
          ],
        ),
        PropRow(
          children: [
            PropNumber(
              label: 'Left',
              value: m['left']!,
              onChange: (v) => _set('left', v),
            ),
            PropNumber(
              label: 'Right',
              value: m['right']!,
              onChange: (v) => _set('right', v),
            ),
          ],
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  const _PanelHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A45))),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _EmptyProps extends StatelessWidget {
  const _EmptyProps();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tune, color: Colors.white24, size: 36),
          SizedBox(height: 8),
          Text(
            'Select a widget',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ImageProps extends StatelessWidget {
  final WidgetNode node;
  final void Function(String, dynamic) setProp;
  const _ImageProps({required this.node, required this.setProp});

  @override
  Widget build(BuildContext context) {
    final p = node.props;
    return PropGroup(
      children: [
        PropDropdown(
          label: 'Source',
          value: p['imageSource'] ?? 'network',
          options: const ['network', 'asset'],
          onChange: (v) => setProp('imageSource', v),
        ),
        if (p['imageSource'] == 'network')
          PropTextField(
            label: 'URL',
            value: p['url'] ?? '',
            onChange: (v) => setProp('url', v),
          )
        else
          PropTextField(
            label: 'Asset Path',
            value: p['assetPath'] ?? '',
            onChange: (v) => setProp('assetPath', v),
          ),
        const PropSectionLabel('Size & Fit'),
        PropDropdown(
          label: 'Fit',
          value: p['fit'] ?? 'cover',
          options: const [
            'fill',
            'contain',
            'cover',
            'fitWidth',
            'fitHeight',
            'none',
            'scaleDown',
          ],
          onChange: (v) => setProp('fit', v),
        ),
        PropRow(
          children: [
            PropDropdown(
              label: 'Width',
              value: p['widthMode'] ?? 'wrap',
              options: const ['wrap', 'fill', 'fixed'],
              onChange: (v) => setProp('widthMode', v),
            ),
            if (p['widthMode'] == 'fixed')
              PropNumber(
                label: 'W px',
                value: (p['widthValue'] as num?)?.toDouble() ?? 100,
                onChange: (v) => setProp('widthValue', v),
              ),
          ],
        ),
        PropRow(
          children: [
            PropDropdown(
              label: 'Height',
              value: p['heightMode'] ?? 'wrap',
              options: const ['wrap', 'fill', 'fixed'],
              onChange: (v) => setProp('heightMode', v),
            ),
            if (p['heightMode'] == 'fixed')
              PropNumber(
                label: 'H px',
                value: (p['heightValue'] as num?)?.toDouble() ?? 200,
                onChange: (v) => setProp('heightValue', v),
              ),
          ],
        ),
      ],
    );
  }
}
