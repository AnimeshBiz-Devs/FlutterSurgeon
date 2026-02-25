enum ChildCapacity { none, single, multi, scaffold }

enum WidgetCategory {
  root,
  layoutMulti,
  layoutSingle,
  display,
  input,
  navigation,
  decoration,
}

enum WidgetType {
  // Root
  scaffold,
  safeArea,

  // Layout Multi-child
  column,
  row,
  stack,
  wrap,
  listView,

  // Layout Single-child
  container,
  center,
  padding,
  align,
  expanded,
  sizedBox,
  clipRRect,
  gestureDetector,
  inkWell,

  // Display
  text,
  icon,
  image,
  divider,
  circleAvatar,

  // Input / Interactive
  elevatedButton,
  textButton,
  outlinedButton,
  iconButton,
  textField,

  // Navigation
  appBar,
  bottomNavigationBar,
  floatingActionButton,
  drawer,

  // Decoration
  card,
  listTile,
  chip,
}

extension WidgetTypeExt on WidgetType {
  String get displayName {
    const names = {
      WidgetType.scaffold: 'Scaffold',
      WidgetType.safeArea: 'SafeArea',
      WidgetType.column: 'Column',
      WidgetType.row: 'Row',
      WidgetType.stack: 'Stack',
      WidgetType.wrap: 'Wrap',
      WidgetType.listView: 'ListView',
      WidgetType.container: 'Container',
      WidgetType.center: 'Center',
      WidgetType.padding: 'Padding',
      WidgetType.align: 'Align',
      WidgetType.expanded: 'Expanded',
      WidgetType.sizedBox: 'SizedBox',
      WidgetType.clipRRect: 'ClipRRect',
      WidgetType.gestureDetector: 'GestureDetector',
      WidgetType.inkWell: 'InkWell',
      WidgetType.text: 'Text',
      WidgetType.icon: 'Icon',
      WidgetType.image: 'Image.asset',
      WidgetType.divider: 'Divider',
      WidgetType.circleAvatar: 'CircleAvatar',
      WidgetType.elevatedButton: 'ElevatedButton',
      WidgetType.textButton: 'TextButton',
      WidgetType.outlinedButton: 'OutlinedButton',
      WidgetType.iconButton: 'IconButton',
      WidgetType.textField: 'TextField',
      WidgetType.appBar: 'AppBar',
      WidgetType.bottomNavigationBar: 'BottomNavigationBar',
      WidgetType.floatingActionButton: 'FloatingActionButton',
      WidgetType.drawer: 'Drawer',
      WidgetType.card: 'Card',
      WidgetType.listTile: 'ListTile',
      WidgetType.chip: 'Chip',
    };
    return names[this] ?? name;
  }

  ChildCapacity get childCapacity {
    switch (this) {
      case WidgetType.scaffold:
        return ChildCapacity.scaffold;
      case WidgetType.column:
      case WidgetType.row:
      case WidgetType.stack:
      case WidgetType.wrap:
      case WidgetType.listView:
        return ChildCapacity.multi;
      case WidgetType.safeArea:
      case WidgetType.container:
      case WidgetType.center:
      case WidgetType.padding:
      case WidgetType.align:
      case WidgetType.expanded:
      case WidgetType.sizedBox:
      case WidgetType.clipRRect:
      case WidgetType.gestureDetector:
      case WidgetType.inkWell:
      case WidgetType.elevatedButton:
      case WidgetType.textButton:
      case WidgetType.outlinedButton:
      case WidgetType.card:
      case WidgetType.drawer:
        return ChildCapacity.single;
      case WidgetType.text:
      case WidgetType.icon:
      case WidgetType.image:
      case WidgetType.divider:
      case WidgetType.circleAvatar:
      case WidgetType.iconButton:
      case WidgetType.textField:
      case WidgetType.appBar:
      case WidgetType.bottomNavigationBar:
      case WidgetType.floatingActionButton:
      case WidgetType.listTile:
      case WidgetType.chip:
        return ChildCapacity.none;
    }
  }

  WidgetCategory get category {
    switch (this) {
      case WidgetType.scaffold:
      case WidgetType.safeArea:
        return WidgetCategory.root;
      case WidgetType.column:
      case WidgetType.row:
      case WidgetType.stack:
      case WidgetType.wrap:
      case WidgetType.listView:
        return WidgetCategory.layoutMulti;
      case WidgetType.container:
      case WidgetType.center:
      case WidgetType.padding:
      case WidgetType.align:
      case WidgetType.expanded:
      case WidgetType.sizedBox:
      case WidgetType.clipRRect:
      case WidgetType.gestureDetector:
      case WidgetType.inkWell:
        return WidgetCategory.layoutSingle;
      case WidgetType.text:
      case WidgetType.icon:
      case WidgetType.image:
      case WidgetType.divider:
      case WidgetType.circleAvatar:
        return WidgetCategory.display;
      case WidgetType.elevatedButton:
      case WidgetType.textButton:
      case WidgetType.outlinedButton:
      case WidgetType.iconButton:
      case WidgetType.textField:
        return WidgetCategory.input;
      case WidgetType.appBar:
      case WidgetType.bottomNavigationBar:
      case WidgetType.floatingActionButton:
      case WidgetType.drawer:
        return WidgetCategory.navigation;
      case WidgetType.card:
      case WidgetType.listTile:
      case WidgetType.chip:
        return WidgetCategory.decoration;
    }
  }

  /// Widgets that can ONLY be placed in Scaffold named slots, not as children
  bool get isScaffoldSlotOnly {
    return this == WidgetType.appBar ||
        this == WidgetType.bottomNavigationBar ||
        this == WidgetType.floatingActionButton ||
        this == WidgetType.drawer;
  }

  /// Validates that [child] can parent [this].
  /// Returns an error string or null if valid.
  String? validateParent(WidgetType? parent) {
    if (this == WidgetType.expanded) {
      if (parent != WidgetType.row &&
          parent != WidgetType.column &&
          parent != WidgetType.wrap) {
        return 'Expanded must be a direct child of Row, Column, or Wrap.';
      }
    }
    if (this == WidgetType.scaffold) {
      return 'Scaffold must be the root widget of a screen.';
    }
    return null;
  }

  String get iconChar {
    const icons = {
      WidgetType.scaffold: '📱',
      WidgetType.safeArea: '🛡',
      WidgetType.column: '⬇',
      WidgetType.row: '➡',
      WidgetType.stack: '🃏',
      WidgetType.wrap: '↰',
      WidgetType.listView: '📋',
      WidgetType.container: '◻',
      WidgetType.center: '⊕',
      WidgetType.padding: '⬚',
      WidgetType.align: '⇲',
      WidgetType.expanded: '⇔',
      WidgetType.sizedBox: '📐',
      WidgetType.clipRRect: '⬛',
      WidgetType.gestureDetector: '👆',
      WidgetType.inkWell: '💧',
      WidgetType.text: 'T',
      WidgetType.icon: '★',
      WidgetType.image: '🖼',
      WidgetType.divider: '—',
      WidgetType.circleAvatar: '👤',
      WidgetType.elevatedButton: '⬜',
      WidgetType.textButton: 'Ⓣ',
      WidgetType.outlinedButton: '◯',
      WidgetType.iconButton: '🔘',
      WidgetType.textField: '✎',
      WidgetType.appBar: '▬',
      WidgetType.bottomNavigationBar: '▬',
      WidgetType.floatingActionButton: '✚',
      WidgetType.drawer: '☰',
      WidgetType.card: '🃏',
      WidgetType.listTile: '☰',
      WidgetType.chip: '●',
    };
    return icons[this] ?? '◇';
  }
}
