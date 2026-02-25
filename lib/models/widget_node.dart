import 'package:uuid/uuid.dart';
import 'widget_type.dart';
import 'widget_props.dart';

const _uuid = Uuid();

class WidgetNode {
  final String id;
  final WidgetType type;
  String label;
  WidgetProps props;

  // Multi-child widgets use this
  List<WidgetNode> children;

  // Single-child widgets use this
  WidgetNode? child;

  // Scaffold-specific named slots (non-body)
  WidgetNode? appBar;
  WidgetNode? bottomNavigationBar;
  WidgetNode? floatingActionButton;
  WidgetNode? drawer;

  WidgetNode({
    String? id,
    required this.type,
    String? label,
    WidgetProps? props,
    List<WidgetNode>? children,
    this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
  }) : id = id ?? _uuid.v4(),
       label = label ?? type.displayName,
       props = props ?? WidgetProps.defaults(type),
       children = children ?? [];

  ChildCapacity get childCapacity => type.childCapacity;

  bool get isLeaf => childCapacity == ChildCapacity.none;
  bool get isSingleChild => childCapacity == ChildCapacity.single;
  bool get isMultiChild => childCapacity == ChildCapacity.multi;
  bool get isScaffold => type == WidgetType.scaffold;

  bool get canAcceptChild {
    if (isLeaf) return false;
    if (isScaffold) return child == null; // body slot
    if (isSingleChild) return child == null;
    return true; // multi-child always can
  }

  /// Add a child respecting capacity rules. Returns error message or null on success.
  String? addChild(WidgetNode node) {
    if (isLeaf) {
      return '${type.displayName} cannot have children.';
    }
    if (isScaffold || isSingleChild) {
      if (child != null) {
        return '${type.displayName} already has a child. Delete or wrap it first.';
      }
      child = node;
      return null;
    }
    // multi-child
    children.add(node);
    return null;
  }

  /// Remove a direct child by id (searches both child and children).
  bool removeChildById(String childId) {
    if (child?.id == childId) {
      child = null;
      return true;
    }
    final idx = children.indexWhere((c) => c.id == childId);
    if (idx != -1) {
      children.removeAt(idx);
      return true;
    }
    if (appBar?.id == childId) {
      appBar = null;
      return true;
    }
    if (bottomNavigationBar?.id == childId) {
      bottomNavigationBar = null;
      return true;
    }
    if (floatingActionButton?.id == childId) {
      floatingActionButton = null;
      return true;
    }
    if (drawer?.id == childId) {
      drawer = null;
      return true;
    }
    return false;
  }

  /// Wrap the single child of this node with [wrapper], placing original child inside wrapper.
  String? wrapChildWith(WidgetNode wrapper) {
    if (child == null && children.isEmpty) {
      return 'No child to wrap.';
    }
    // For single-child: wrap existing child
    if (isSingleChild || isScaffold) {
      wrapper.child = child;
      child = wrapper;
      return null;
    }
    return 'Select a specific child node to wrap.';
  }

  List<WidgetNode> get allDirectChildren {
    final result = <WidgetNode>[];
    if (child != null) result.add(child!);
    result.addAll(children);
    if (appBar != null) result.add(appBar!);
    if (bottomNavigationBar != null) result.add(bottomNavigationBar!);
    if (floatingActionButton != null) result.add(floatingActionButton!);
    if (drawer != null) result.add(drawer!);
    return result;
  }

  /// Clones the node exactly, PRESERVING the ID. Use this for immutable state updates.
  WidgetNode exactClone() {
    return WidgetNode(
      id: id,
      type: type,
      label: label,
      props: props.clone(),
      children: children.map((c) => c.exactClone()).toList(),
      child: child?.exactClone(),
      appBar: appBar?.exactClone(),
      bottomNavigationBar: bottomNavigationBar?.exactClone(),
      floatingActionButton: floatingActionButton?.exactClone(),
      drawer: drawer?.exactClone(),
    );
  }

  /// Clones the node with a NEW ID. Use this for user 'Duplicate' operations.
  WidgetNode clone() {
    return WidgetNode(
      id: _uuid.v4(),
      type: type,
      label: '$label (copy)',
      props: props.clone(),
      children: children.map((c) => c.clone()).toList(),
      child: child?.clone(),
      appBar: appBar?.clone(),
      bottomNavigationBar: bottomNavigationBar?.clone(),
      floatingActionButton: floatingActionButton?.clone(),
      drawer: drawer?.clone(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'label': label,
    'props': props.toJson(),
    'children': children.map((c) => c.toJson()).toList(),
    if (child != null) 'child': child!.toJson(),
    if (appBar != null) 'appBar': appBar!.toJson(),
    if (bottomNavigationBar != null)
      'bottomNavigationBar': bottomNavigationBar!.toJson(),
    if (floatingActionButton != null)
      'floatingActionButton': floatingActionButton!.toJson(),
    if (drawer != null) 'drawer': drawer!.toJson(),
  };

  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    final type = WidgetType.values.byName(json['type'] as String);
    return WidgetNode(
      id: json['id'] as String,
      type: type,
      label: json['label'] as String,
      props: WidgetProps.fromJson(json['props'] as Map<String, dynamic>, type),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      child: json['child'] != null
          ? WidgetNode.fromJson(json['child'] as Map<String, dynamic>)
          : null,
      appBar: json['appBar'] != null
          ? WidgetNode.fromJson(json['appBar'] as Map<String, dynamic>)
          : null,
      bottomNavigationBar: json['bottomNavigationBar'] != null
          ? WidgetNode.fromJson(
              json['bottomNavigationBar'] as Map<String, dynamic>,
            )
          : null,
      floatingActionButton: json['floatingActionButton'] != null
          ? WidgetNode.fromJson(
              json['floatingActionButton'] as Map<String, dynamic>,
            )
          : null,
      drawer: json['drawer'] != null
          ? WidgetNode.fromJson(json['drawer'] as Map<String, dynamic>)
          : null,
    );
  }
}
