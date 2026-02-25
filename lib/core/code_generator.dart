import '../models/index.dart';

/// Walks the WidgetNode tree and emits clean Flutter/Dart code.
class CodeGenerator {
  final StringBuffer _buf = StringBuffer();
  int _indent = 0;

  String generateProject(
    Map<String, WidgetNode> screens,
    String initialScreen,
  ) {
    _buf.clear();
    _indent = 0;

    _line("import 'package:flutter/material.dart';");
    _line('');
    _line('void main() {');
    _line('  runApp(const MyApp());');
    _line('}');
    _line('');
    _line('class MyApp extends StatelessWidget {');
    _indent++;
    _line('const MyApp({super.key});');
    _line('');
    _line('@override');
    _line('Widget build(BuildContext context) {');
    _indent++;
    _line('return MaterialApp(');
    _indent++;
    _line("title: 'FlutterSurgeon App',");
    _line("initialRoute: '/$initialScreen',");
    _line('routes: {');
    _indent++;
    for (final screenName in screens.keys) {
      _line("'/\\$screenName': (context) => const \$screenName(),");
    }
    _indent--;
    _line('},');
    _line('debugShowCheckedModeBanner: false,');
    _indent--;
    _line(');');
    _indent--;
    _line('}');
    _indent--;
    _line('}');
    _line('');

    for (final entry in screens.entries) {
      _generateScreenClass(entry.key, entry.value);
    }

    return _buf.toString();
  }

  void _generateScreenClass(String screenName, WidgetNode root) {
    _line('class $screenName extends StatelessWidget {');
    _indent++;
    _line('const $screenName({super.key});');
    _line('');
    _line('@override');
    _line('Widget build(BuildContext context) {');
    _indent++;
    _write('return ');
    _emitNode(root);
    _line(';');
    _indent--;
    _line('}');
    _indent--;
    _line('}');
    _line('');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _onTapAction(WidgetProps p) {
    final nav = p['onTapNavigateTo'] as String?;
    if (nav != null && nav.isNotEmpty) {
      return "() { Navigator.pushNamed(context, '/\$nav'); }";
    }
    return "() {}";
  }

  // ── Routing ───────────────────────────────────────────────────────────────
  void _emitNode(WidgetNode node) {
    switch (node.type) {
      case WidgetType.scaffold:
        _emitScaffold(node);
      case WidgetType.safeArea:
        _emitSafeArea(node);
      case WidgetType.column:
        _emitColumnRow(node, 'Column');
      case WidgetType.row:
        _emitColumnRow(node, 'Row');
      case WidgetType.stack:
        _emitStack(node);
      case WidgetType.wrap:
        _emitWrap(node);
      case WidgetType.listView:
        _emitListView(node);
      case WidgetType.container:
        _emitContainer(node);
      case WidgetType.center:
        _emitSingleParent(node, 'Center', {});
      case WidgetType.padding:
        _emitPadding(node);
      case WidgetType.align:
        _emitAlign(node);
      case WidgetType.expanded:
        _emitExpanded(node);
      case WidgetType.sizedBox:
        _emitSizedBox(node);
      case WidgetType.clipRRect:
        _emitClipRRect(node);
      case WidgetType.gestureDetector:
        _emitSingleParent(node, 'GestureDetector', {
          'onTap': _onTapAction(node.props),
        });
      case WidgetType.inkWell:
        _emitSingleParent(node, 'InkWell', {'onTap': _onTapAction(node.props)});
      case WidgetType.text:
        _emitText(node);
      case WidgetType.icon:
        _emitIcon(node);
      case WidgetType.image:
        _emitImage(node);
      case WidgetType.divider:
        _emitDivider(node);
      case WidgetType.circleAvatar:
        _emitCircleAvatar(node);
      case WidgetType.elevatedButton:
        _emitButton(node, 'ElevatedButton');
      case WidgetType.textButton:
        _emitButton(node, 'TextButton');
      case WidgetType.outlinedButton:
        _emitButton(node, 'OutlinedButton');
      case WidgetType.iconButton:
        _emitIconButton(node);
      case WidgetType.textField:
        _emitTextField(node);
      case WidgetType.appBar:
        _emitAppBar(node);
      case WidgetType.bottomNavigationBar:
        _emitBottomNav(node);
      case WidgetType.floatingActionButton:
        _emitFAB(node);
      case WidgetType.drawer:
        _emitSingleParent(node, 'Drawer', {});
      case WidgetType.card:
        _emitCard(node);
      case WidgetType.listTile:
        _emitListTile(node);
      case WidgetType.chip:
        _emitChip(node);
    }
  }

  // ── Implementations ───────────────────────────────────────────────────────

  void _emitScaffold(WidgetNode node) {
    final p = node.props;
    _write('Scaffold(');
    _indent++;
    if (p['backgroundColor'] != null) {
      _line('backgroundColor: ${_color(p['backgroundColor'])},');
    }
    if (node.appBar != null) {
      _writeIndent();
      _buf.write('appBar: ');
      _emitNode(node.appBar!);
      _buf.write(',\n');
    }
    if (node.child != null) {
      _writeIndent();
      _buf.write('body: ');
      _emitNode(node.child!);
      _buf.write(',\n');
    }
    if (node.bottomNavigationBar != null) {
      _writeIndent();
      _buf.write('bottomNavigationBar: ');
      _emitNode(node.bottomNavigationBar!);
      _buf.write(',\n');
    }
    if (node.floatingActionButton != null) {
      _writeIndent();
      _buf.write('floatingActionButton: ');
      _emitNode(node.floatingActionButton!);
      _buf.write(',\n');
    }
    if (node.drawer != null) {
      _writeIndent();
      _buf.write('drawer: ');
      _emitNode(node.drawer!);
      _buf.write(',\n');
    }
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitSafeArea(WidgetNode node) {
    final p = node.props;
    _write('SafeArea(');
    _indent++;
    if (p['top'] == false) _line('top: false,');
    if (p['bottom'] == false) _line('bottom: false,');
    if (p['left'] == false) _line('left: false,');
    if (p['right'] == false) _line('right: false,');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitColumnRow(WidgetNode node, String widgetName) {
    final p = node.props;
    _write('$widgetName(');
    _indent++;
    _emitAxisProps(p);
    _line('children: [');
    _indent++;
    for (final c in node.children) {
      _writeIndent();
      _emitNode(c);
      _buf.write(',\n');
    }
    _indent--;
    _line('],');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitStack(WidgetNode node) {
    final p = node.props;
    _write('Stack(');
    _indent++;
    if (p['alignment'] != 'topLeft') {
      _line('alignment: ${_alignment(p['alignment'])},');
    }
    _line('children: [');
    _indent++;
    for (final c in node.children) {
      _writeIndent();
      _emitNode(c);
      _buf.write(',\n');
    }
    _indent--;
    _line('],');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitWrap(WidgetNode node) {
    final p = node.props;
    _write('Wrap(');
    _indent++;
    if ((p['spacing'] as num) != 0) _line('spacing: ${p['spacing']},');
    if ((p['runSpacing'] as num) != 0) _line('runSpacing: ${p['runSpacing']},');
    _line('children: [');
    _indent++;
    for (final c in node.children) {
      _writeIndent();
      _emitNode(c);
      _buf.write(',\n');
    }
    _indent--;
    _line('],');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitListView(WidgetNode node) {
    _write('ListView(');
    _indent++;
    _line('children: [');
    _indent++;
    for (final c in node.children) {
      _writeIndent();
      _emitNode(c);
      _buf.write(',\n');
    }
    _indent--;
    _line('],');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitContainer(WidgetNode node) {
    final p = node.props;
    final hasDecoration =
        p['color'] != null ||
        p['useGradient'] == true ||
        (p['borderRadius'] as num) > 0 ||
        p['borderColor'] != null;

    _write('Container(');
    _indent++;

    // Size
    _emitWidthHeight(p);

    // Padding
    final pad = _edgeMap(p['padding']);
    if (!pad.isZero) _line('padding: ${_edgeInsets(pad)},');

    // Margin
    final mar = _edgeMap(p['margin']);
    if (!mar.isZero) _line('margin: ${_edgeInsets(mar)},');

    // Decoration
    if (hasDecoration) {
      _line('decoration: BoxDecoration(');
      _indent++;
      if (p['color'] != null && p['useGradient'] != true) {
        _line('color: ${_color(p['color'])},');
      }
      if (p['useGradient'] == true) {
        final c1 = _color(p['gradientColor1'] ?? '#FF5555');
        final c2 = _color(p['gradientColor2'] ?? '#5555FF');
        final begin = p['gradientBegin'] ?? 'topLeft';
        final end = p['gradientEnd'] ?? 'bottomRight';

        _line('gradient: LinearGradient(');
        _indent++;
        _line('begin: Alignment.$begin,');
        _line('end: Alignment.$end,');
        _line('colors: [$c1, $c2],');
        _indent--;
        _line('),');
      }
      if ((p['borderRadius'] as num) > 0) {
        _line(
          'borderRadius: BorderRadius.circular(${_num(p['borderRadius'])}),',
        );
      }
      if (p['borderColor'] != null) {
        _line('border: Border.all(');
        _indent++;
        _line('color: ${_color(p['borderColor'])},');
        if ((p['borderWidth'] as num? ?? 1) != 1) {
          _line('width: ${_num(p['borderWidth'])},');
        }
        _indent--;
        _line('),');
      }
      _indent--;
      _line('),');
    }

    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitPadding(WidgetNode node) {
    final p = node.props;
    _write('Padding(');
    _indent++;
    final pad = _edgeMap(p['padding']);
    _line('padding: ${_edgeInsets(pad)},');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitAlign(WidgetNode node) {
    final p = node.props;
    _write('Align(');
    _indent++;
    _line('alignment: ${_alignment(p['alignment'])},');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitExpanded(WidgetNode node) {
    final p = node.props;
    _write('Expanded(');
    _indent++;
    if ((p['flex'] as int? ?? 1) != 1) _line('flex: ${p['flex']},');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitSizedBox(WidgetNode node) {
    final p = node.props;
    final w = p['width'] as num? ?? 0;
    final h = p['height'] as num? ?? 0;
    if (w == 0 && h == 0) {
      _write('const SizedBox()');
      return;
    }
    _write('SizedBox(');
    _indent++;
    if (w != 0) _line('width: $w,');
    if (h != 0) _line('height: $h,');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitClipRRect(WidgetNode node) {
    final p = node.props;
    _write('ClipRRect(');
    _indent++;
    _line('borderRadius: BorderRadius.circular(${_num(p['borderRadius'])}),');
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitSingleParent(
    WidgetNode node,
    String name,
    Map<String, String> extra,
  ) {
    _write('$name(');
    _indent++;
    for (final e in extra.entries) {
      _line('${e.key}: ${e.value},');
    }
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitText(WidgetNode node) {
    final p = node.props;
    final content = (p['content'] as String? ?? '').replaceAll("'", "\\'");
    _write("Text(");
    _indent++;
    _line("'$content',");
    _line('style: TextStyle(');
    _indent++;
    if ((p['fontSize'] as num?) != 16)
      _line('fontSize: ${_num(p['fontSize'])},');
    if (p['fontWeight'] != 'normal') {
      _line('fontWeight: ${_fontWeight(p['fontWeight'])},');
    }
    if (p['color'] != null) _line('color: ${_color(p['color'])},');
    if (p['italic'] == true) _line('fontStyle: FontStyle.italic,');
    if (p['letterSpacing'] != null)
      _line('letterSpacing: ${_num(p['letterSpacing'])},');
    _indent--;
    _line('),');
    if (p['textAlign'] != null && p['textAlign'] != 'left') {
      _line('textAlign: ${_textAlign(p['textAlign'])},');
    }
    if (p['maxLines'] != null) _line('maxLines: ${p['maxLines']},');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitIcon(WidgetNode node) {
    final p = node.props;
    _write(
      'Icon(Icons.${p['iconName']}, size: ${_num(p['size'])}, color: ${_color(p['color'])})',
    );
  }

  void _emitImage(WidgetNode node) {
    final p = node.props;
    final src = p['imageSource'] ?? 'network';
    if (src == 'network') {
      _write("Image.network('${p['url'] ?? ''}', fit: BoxFit.${p['fit']},");
    } else {
      _write("Image.asset('${p['assetPath'] ?? ''}', fit: BoxFit.${p['fit']},");
    }
    _emitWidthHeightInline(p);
    _buf.write(')');
  }

  void _emitDivider(WidgetNode node) {
    final p = node.props;
    _write(
      'Divider(height: ${_num(p['height'])}, thickness: ${_num(p['thickness'])}, color: ${_color(p['color'])})',
    );
  }

  void _emitCircleAvatar(WidgetNode node) {
    final p = node.props;
    _write('CircleAvatar(');
    _indent++;
    _line('radius: ${_num(p['radius'])},');
    if (p['backgroundColor'] != null)
      _line('backgroundColor: ${_color(p['backgroundColor'])},');
    _line("child: Text('${p['initials']}'),");
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitButton(WidgetNode node, String name) {
    final p = node.props;
    _write('$name(');
    _indent++;
    _line('onPressed: ${_onTapAction(p)},');
    final hasStyle =
        p['backgroundColor'] != null ||
        p['foregroundColor'] != null ||
        (p['borderRadius'] as num?) != null;
    if (hasStyle) {
      _line('style: $name.styleFrom(');
      _indent++;
      if (p['backgroundColor'] != null)
        _line('backgroundColor: ${_color(p['backgroundColor'])},');
      if (p['foregroundColor'] != null)
        _line('foregroundColor: ${_color(p['foregroundColor'])},');
      if ((p['borderRadius'] as num? ?? 8) != 8) {
        _line(
          'shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_num(p['borderRadius'])})),',
        );
      }
      _indent--;
      _line('),');
    }
    if (node.child != null) {
      _writeIndent();
      _buf.write('child: ');
      _emitNode(node.child!);
      _buf.write(',\n');
    } else {
      _line("child: const Text('Button'),");
    }
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitIconButton(WidgetNode node) {
    final p = node.props;
    _write(
      'IconButton(onPressed: ${_onTapAction(p)}, icon: Icon(Icons.${p['iconName']}, size: ${_num(p['iconSize'])}, color: ${_color(p['color'])}))',
    );
  }

  void _emitTextField(WidgetNode node) {
    final p = node.props;
    _write('TextField(');
    _indent++;
    _line('decoration: InputDecoration(');
    _indent++;
    if ((p['hintText'] as String? ?? '').isNotEmpty)
      _line("hintText: '${p['hintText']}',");
    if ((p['labelText'] as String? ?? '').isNotEmpty)
      _line("labelText: '${p['labelText']}',");
    _indent--;
    _line('),');
    if (p['obscureText'] == true) _line('obscureText: true,');
    if ((p['maxLines'] as int? ?? 1) > 1) _line('maxLines: ${p['maxLines']},');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitAppBar(WidgetNode node) {
    final p = node.props;
    _write('AppBar(');
    _indent++;
    _line("title: Text('${p['title']}'),");
    if (p['centerTitle'] == true) _line('centerTitle: true,');
    if (p['elevation'] != null && (p['elevation'] as num) == 0)
      _line('elevation: 0,');
    if (p['backgroundColor'] != null)
      _line('backgroundColor: ${_color(p['backgroundColor'])},');
    if (p['foregroundColor'] != null)
      _line('foregroundColor: ${_color(p['foregroundColor'])},');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitBottomNav(WidgetNode node) {
    final p = node.props;
    final items = (p['items'] as List<dynamic>? ?? ['Home', 'Search']);
    _write('BottomNavigationBar(');
    _indent++;
    _line('currentIndex: ${p['currentIndex'] ?? 0},');
    _line('onTap: ${_onTapAction(p)},');
    _line('items: [');
    _indent++;
    for (final item in items) {
      _line(
        "BottomNavigationBarItem(icon: Icon(Icons.label), label: '$item'),",
      );
    }
    _indent--;
    _line('],');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitFAB(WidgetNode node) {
    final p = node.props;
    _write('FloatingActionButton(');
    _indent++;
    _line('onPressed: ${_onTapAction(p)},');
    if (p['tooltip'] != null) _line("tooltip: '${p['tooltip']}',");
    if (p['backgroundColor'] != null)
      _line('backgroundColor: ${_color(p['backgroundColor'])},');
    _line('child: Icon(Icons.${p['iconName'] ?? 'add'}),');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitCard(WidgetNode node) {
    final p = node.props;
    _write('Card(');
    _indent++;
    if ((p['elevation'] as num? ?? 4) != 4)
      _line('elevation: ${_num(p['elevation'])},');
    if (p['color'] != null) _line('color: ${_color(p['color'])},');
    if ((p['borderRadius'] as num? ?? 12) != 12) {
      _line(
        'shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_num(p['borderRadius'])})),',
      );
    }
    _writeChildOrEmpty(node);
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitListTile(WidgetNode node) {
    final p = node.props;
    _write('ListTile(');
    _indent++;
    _line("title: Text('${p['title']}'),");
    if ((p['subtitle'] as String? ?? '').isNotEmpty)
      _line("subtitle: Text('${p['subtitle']}'),");
    if (p['leadingIcon'] != null)
      _line('leading: Icon(Icons.${p['leadingIcon']}),');
    if (p['trailingIcon'] != null)
      _line('trailing: Icon(Icons.${p['trailingIcon']}),');
    _line('onTap: ${_onTapAction(p)},');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  void _emitChip(WidgetNode node) {
    final p = node.props;
    _write('Chip(');
    _indent++;
    _line("label: Text('${p['label']}'),");
    if (p['backgroundColor'] != null)
      _line('backgroundColor: ${_color(p['backgroundColor'])},');
    _indent--;
    _writeIndent();
    _buf.write(')');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _writeChildOrEmpty(WidgetNode node) {
    if (node.child != null) {
      _writeIndent();
      _buf.write('child: ');
      _emitNode(node.child!);
      _buf.write(',\n');
    }
  }

  void _emitAxisProps(WidgetProps p) {
    if (p['mainAxisAlignment'] != 'start') {
      _line('mainAxisAlignment: ${_mainAxis(p['mainAxisAlignment'])},');
    }
    if (p['crossAxisAlignment'] != 'center') {
      _line('crossAxisAlignment: ${_crossAxis(p['crossAxisAlignment'])},');
    }
    if (p['mainAxisSize'] == 'min') {
      _line('mainAxisSize: MainAxisSize.min,');
    }
  }

  void _emitWidthHeight(WidgetProps p) {
    final wMode = p['widthMode'] as String? ?? 'wrap';
    final hMode = p['heightMode'] as String? ?? 'wrap';
    if (wMode == 'fill') {
      _line('width: double.infinity,');
    } else if (wMode == 'fixed') {
      _line('width: ${_num(p['widthValue'])},');
    }
    if (hMode == 'fill') {
      _line('height: double.infinity,');
    } else if (hMode == 'fixed') {
      _line('height: ${_num(p['heightValue'])},');
    }
  }

  void _emitWidthHeightInline(WidgetProps p) {
    final wMode = p['widthMode'] as String? ?? 'wrap';
    final hMode = p['heightMode'] as String? ?? 'wrap';
    if (wMode == 'fill') {
      _buf.write(' width: double.infinity,');
    } else if (wMode == 'fixed') {
      _buf.write(' width: ${_num(p['widthValue'])},');
    }
    if (hMode == 'fill') {
      _buf.write(' height: double.infinity,');
    } else if (hMode == 'fixed') {
      _buf.write(' height: ${_num(p['heightValue'])},');
    }
  }

  // ── Formatters ────────────────────────────────────────────────────────────
  String _color(dynamic hex) {
    if (hex == null) return 'Colors.transparent';
    final h = (hex as String).replaceFirst('#', '');
    if (h.length == 6) return 'const Color(0xFF$h)';
    if (h.length == 8) return 'const Color(0x$h)';
    return 'Colors.transparent';
  }

  String _num(dynamic v) {
    if (v == null) return '0';
    final d = (v as num).toDouble();
    return d == d.truncateToDouble() ? d.truncate().toString() : d.toString();
  }

  String _mainAxis(dynamic v) {
    const map = {
      'start': 'MainAxisAlignment.start',
      'center': 'MainAxisAlignment.center',
      'end': 'MainAxisAlignment.end',
      'spaceBetween': 'MainAxisAlignment.spaceBetween',
      'spaceAround': 'MainAxisAlignment.spaceAround',
      'spaceEvenly': 'MainAxisAlignment.spaceEvenly',
    };
    return map[v] ?? 'MainAxisAlignment.start';
  }

  String _crossAxis(dynamic v) {
    const map = {
      'start': 'CrossAxisAlignment.start',
      'center': 'CrossAxisAlignment.center',
      'end': 'CrossAxisAlignment.end',
      'stretch': 'CrossAxisAlignment.stretch',
      'baseline': 'CrossAxisAlignment.baseline',
    };
    return map[v] ?? 'CrossAxisAlignment.center';
  }

  String _alignment(dynamic v) {
    const map = {
      'topLeft': 'Alignment.topLeft',
      'topCenter': 'Alignment.topCenter',
      'topRight': 'Alignment.topRight',
      'centerLeft': 'Alignment.centerLeft',
      'center': 'Alignment.center',
      'centerRight': 'Alignment.centerRight',
      'bottomLeft': 'Alignment.bottomLeft',
      'bottomCenter': 'Alignment.bottomCenter',
      'bottomRight': 'Alignment.bottomRight',
    };
    return map[v] ?? 'Alignment.center';
  }

  String _textAlign(dynamic v) {
    const map = {
      'left': 'TextAlign.left',
      'center': 'TextAlign.center',
      'right': 'TextAlign.right',
      'justify': 'TextAlign.justify',
    };
    return map[v] ?? 'TextAlign.left';
  }

  String _fontWeight(dynamic v) {
    const map = {
      'bold': 'FontWeight.bold',
      'w100': 'FontWeight.w100',
      'w200': 'FontWeight.w200',
      'w300': 'FontWeight.w300',
      'w400': 'FontWeight.w400',
      'w500': 'FontWeight.w500',
      'w600': 'FontWeight.w600',
      'w700': 'FontWeight.w700',
      'w800': 'FontWeight.w800',
      'w900': 'FontWeight.w900',
    };
    return map[v] ?? 'FontWeight.normal';
  }

  String _edgeInsets(_EdgeMap e) {
    if (e.isAll) return 'const EdgeInsets.all(${_num(e.top)})';
    if (e.isSymmetric) {
      return 'const EdgeInsets.symmetric(horizontal: ${_num(e.left)}, vertical: ${_num(e.top)})';
    }
    return 'const EdgeInsets.fromLTRB(${_num(e.left)}, ${_num(e.top)}, ${_num(e.right)}, ${_num(e.bottom)})';
  }

  _EdgeMap _edgeMap(dynamic v) {
    if (v is! Map) return _EdgeMap.zero();
    return _EdgeMap(
      top: (v['top'] as num?)?.toDouble() ?? 0,
      right: (v['right'] as num?)?.toDouble() ?? 0,
      bottom: (v['bottom'] as num?)?.toDouble() ?? 0,
      left: (v['left'] as num?)?.toDouble() ?? 0,
    );
  }

  // ── Write helpers ─────────────────────────────────────────────────────────
  void _line(String text) {
    _writeIndent();
    _buf.writeln(text);
  }

  void _write(String text) {
    _writeIndent();
    _buf.write(text);
  }

  void _writeIndent() {
    _buf.write('  ' * _indent);
  }
}

class _EdgeMap {
  final double top, right, bottom, left;
  _EdgeMap({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });
  factory _EdgeMap.zero() => _EdgeMap(top: 0, right: 0, bottom: 0, left: 0);

  bool get isZero => top == 0 && right == 0 && bottom == 0 && left == 0;
  bool get isAll => top == right && right == bottom && bottom == left;
  bool get isSymmetric => top == bottom && left == right && top != left;
}
