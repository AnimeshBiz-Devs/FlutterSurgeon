import 'widget_node.dart';

class ProjectModel {
  String screenName; // Currently active screen when saved
  double canvasWidth;
  double canvasHeight;
  Map<String, WidgetNode>? screens;
  WidgetNode? root; // Legacy single-screen support
  final String version = '1.0';

  ProjectModel({
    this.screenName = 'HomeScreen',
    this.canvasWidth = 390,
    this.canvasHeight = 844,
    this.screens,
    this.root,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'screenName': screenName,
    'canvasSize': {'width': canvasWidth, 'height': canvasHeight},
    if (screens != null)
      'screens': screens!.map((k, v) => MapEntry(k, v.toJson())),
    if (root != null)
      'tree': root!.toJson(), // Keep legacy field around if we want
  };

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    final size = json['canvasSize'] as Map<String, dynamic>?;

    Map<String, WidgetNode>? parsedScreens;
    if (json['screens'] != null) {
      final map = json['screens'] as Map<String, dynamic>;
      parsedScreens = map.map(
        (k, v) => MapEntry(k, WidgetNode.fromJson(v as Map<String, dynamic>)),
      );
    }

    return ProjectModel(
      screenName: json['screenName'] as String? ?? 'HomeScreen',
      canvasWidth: (size?['width'] as num?)?.toDouble() ?? 390,
      canvasHeight: (size?['height'] as num?)?.toDouble() ?? 844,
      screens: parsedScreens,
      root: json['tree'] != null
          ? WidgetNode.fromJson(json['tree'] as Map<String, dynamic>)
          : null,
    );
  }
}
