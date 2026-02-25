import 'widget_type.dart';

/// Holds all configurable properties for a WidgetNode.
/// Uses a loose Map<String, dynamic> internally so new props
/// can be added per widget type without needing new fields.
class WidgetProps {
  final Map<String, dynamic> _data;

  WidgetProps(this._data);

  dynamic operator [](String key) => _data[key];
  void set(String key, dynamic value) => _data[key] = value;
  bool has(String key) => _data.containsKey(key);

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_data);

  WidgetProps clone() => WidgetProps(Map<String, dynamic>.from(_data));

  factory WidgetProps.fromJson(Map<String, dynamic> json, WidgetType type) {
    final defaults = WidgetProps.defaults(type);
    for (final entry in json.entries) {
      defaults.set(entry.key, entry.value);
    }
    return defaults;
  }

  /// Returns default props for a given widget type.
  factory WidgetProps.defaults(WidgetType type) {
    switch (type) {
      // --- Root ---
      case WidgetType.scaffold:
        return WidgetProps({'backgroundColor': null});

      case WidgetType.safeArea:
        return WidgetProps({
          'top': true,
          'bottom': true,
          'left': true,
          'right': true,
        });

      // --- Multi-child layout ---
      case WidgetType.column:
        return WidgetProps({
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'center',
          'mainAxisSize': 'max',
        });

      case WidgetType.row:
        return WidgetProps({
          'mainAxisAlignment': 'start',
          'crossAxisAlignment': 'center',
          'mainAxisSize': 'max',
        });

      case WidgetType.stack:
        return WidgetProps({'alignment': 'topLeft', 'fit': 'loose'});

      case WidgetType.wrap:
        return WidgetProps({
          'direction': 'horizontal',
          'alignment': 'start',
          'spacing': 0.0,
          'runSpacing': 0.0,
        });

      case WidgetType.listView:
        return WidgetProps({
          'scrollDirection': 'vertical',
          'padding': _EdgeInsets.zero().toMap(),
        });

      // --- Single-child layout ---
      case WidgetType.container:
        return WidgetProps({
          'widthMode': 'wrap', // wrap | fill | fixed
          'widthValue': 100.0,
          'heightMode': 'wrap',
          'heightValue': 100.0,
          'padding': _EdgeInsets.zero().toMap(),
          'margin': _EdgeInsets.zero().toMap(),
          'color': null, // hex string
          'useGradient': false,
          'gradientColor1': '#FF5555',
          'gradientColor2': '#5555FF',
          'gradientBegin': 'topLeft',
          'gradientEnd': 'bottomRight',
          'borderRadius': 0.0,
          'borderColor': null,
          'borderWidth': 0.0,
          'clipBehavior': 'none',
        });

      case WidgetType.center:
        return WidgetProps({'widthFactor': null, 'heightFactor': null});

      case WidgetType.padding:
        return WidgetProps({'padding': _EdgeInsets.all(8).toMap()});

      case WidgetType.align:
        return WidgetProps({'alignment': 'center'});

      case WidgetType.expanded:
        return WidgetProps({'flex': 1});

      case WidgetType.sizedBox:
        return WidgetProps({'width': 0.0, 'height': 0.0});

      case WidgetType.clipRRect:
        return WidgetProps({'borderRadius': 8.0});

      case WidgetType.gestureDetector:
      case WidgetType.inkWell:
        return WidgetProps({});

      // --- Display ---
      case WidgetType.text:
        return WidgetProps({
          'content': 'Text',
          'fontSize': 16.0,
          'fontWeight': 'normal', // normal | bold | w100..w900
          'color': '#FFFFFF',
          'textAlign': 'left',
          'maxLines': null,
          'overflow': 'clip',
          'italic': false,
          'letterSpacing': null,
        });

      case WidgetType.icon:
        return WidgetProps({
          'iconName': 'star',
          'size': 24.0,
          'color': '#FFFFFF',
        });

      case WidgetType.image:
        return WidgetProps({
          'imageSource': 'network', // 'network' or 'asset'
          'url': 'https://picsum.photos/400/300',
          'assetPath': 'assets/image.png',
          'widthMode': 'fill',
          'widthValue': 100.0,
          'heightMode': 'fixed',
          'heightValue': 200.0,
          'fit': 'cover',
        });

      case WidgetType.divider:
        return WidgetProps({
          'height': 1.0,
          'thickness': 1.0,
          'color': '#444444',
        });

      case WidgetType.circleAvatar:
        return WidgetProps({
          'radius': 24.0,
          'backgroundColor': '#555555',
          'initials': 'AB',
        });

      // --- Buttons ---
      case WidgetType.elevatedButton:
      case WidgetType.textButton:
      case WidgetType.outlinedButton:
        return WidgetProps({
          'backgroundColor': null,
          'foregroundColor': null,
          'borderRadius': 8.0,
          'padding': _EdgeInsets.symmetric(h: 16, v: 12).toMap(),
        });

      case WidgetType.iconButton:
        return WidgetProps({
          'iconName': 'favorite',
          'iconSize': 24.0,
          'color': '#FFFFFF',
        });

      case WidgetType.textField:
        return WidgetProps({
          'hintText': 'Enter text...',
          'labelText': '',
          'obscureText': false,
          'maxLines': 1,
        });

      // --- Navigation ---
      case WidgetType.appBar:
        return WidgetProps({
          'title': 'Title',
          'backgroundColor': null,
          'foregroundColor': null,
          'centerTitle': true,
          'elevation': 0.0,
        });

      case WidgetType.bottomNavigationBar:
        return WidgetProps({
          'items': ['Home', 'Search', 'Profile'],
          'currentIndex': 0,
          'backgroundColor': null,
        });

      case WidgetType.floatingActionButton:
        return WidgetProps({
          'iconName': 'add',
          'backgroundColor': null,
          'tooltip': 'Action',
        });

      case WidgetType.drawer:
        return WidgetProps({});

      // --- Decoration ---
      case WidgetType.card:
        return WidgetProps({
          'elevation': 4.0,
          'color': null,
          'shape': 'rounded', // rounded | rectangle
          'borderRadius': 12.0,
        });

      case WidgetType.listTile:
        return WidgetProps({
          'title': 'List Item',
          'subtitle': '',
          'leadingIcon': 'label',
          'trailingIcon': 'chevron_right',
        });

      case WidgetType.chip:
        return WidgetProps({
          'label': 'Chip',
          'backgroundColor': null,
          'deleteIcon': false,
        });
    }
  }
}

class _EdgeInsets {
  final double top, right, bottom, left;
  _EdgeInsets({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});
  factory _EdgeInsets.zero() => _EdgeInsets();
  factory _EdgeInsets.all(double v) =>
      _EdgeInsets(top: v, right: v, bottom: v, left: v);
  factory _EdgeInsets.symmetric({double h = 0, double v = 0}) =>
      _EdgeInsets(top: v, right: h, bottom: v, left: h);

  Map<String, dynamic> toMap() => {
    'top': top,
    'right': right,
    'bottom': bottom,
    'left': left,
  };
}
