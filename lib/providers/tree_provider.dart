import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../core/history_manager.dart';

// ── Active screen & Clipboard ────────────────────────────────────────────────
final activeScreenProvider = StateProvider<String>((ref) => 'HomeScreen');
final clipboardProvider = StateProvider<WidgetNode?>((ref) => null);

// ── Widget tree ──────────────────────────────────────────────────────────────
class WidgetTreeNotifier extends Notifier<Map<String, WidgetNode>> {
  late HistoryManager<Map<String, WidgetNode>> _history;

  @override
  Map<String, WidgetNode> build() {
    _history = HistoryManager(clone: _deepCloneMap);
    return {'HomeScreen': WidgetNode(type: WidgetType.scaffold)};
  }

  void addScreen(String name) {
    if (state.containsKey(name)) return;
    _snapshot();
    final cloned = _deepCloneMap(state);
    cloned[name] = WidgetNode(type: WidgetType.scaffold);
    state = cloned;
  }

  void removeScreen(String name) {
    if (state.length <= 1) return; // Keep at least one screen
    _snapshot();
    final cloned = _deepCloneMap(state);
    cloned.remove(name);
    state = cloned;

    // If the active screen was removed, the UI will need to change activeScreenProvider
    // Doing it here is not possible without ref.read since it's a provider,
    // so the caller must handle changing the activeScreenProvider.
  }

  void renameScreen(String oldName, String newName) {
    if (!state.containsKey(oldName) || state.containsKey(newName)) return;
    _snapshot();
    final cloned = _deepCloneMap(state);
    final node = cloned.remove(oldName)!;
    cloned[newName] = node;
    state = cloned;
  }

  void updateNode(String id, void Function(WidgetNode node) updater) {
    _snapshot();
    final cloned = _deepCloneMap(state);
    for (final root in cloned.values) {
      final found = _findById(root, id);
      if (found != null) {
        updater(found);
        state = cloned;
        return;
      }
    }
  }

  /// Add [child] to the node with [parentId]. Returns error string or null.
  String? addChild(String parentId, WidgetNode child, {String? slotName}) {
    final cloned = _deepCloneMap(state);
    WidgetNode? parent;
    for (final root in cloned.values) {
      parent = _findById(root, parentId);
      if (parent != null) break;
    }
    if (parent == null) return 'Parent not found.';

    // Validate if adding to specific scaffold slot
    if (slotName != null && parent.type == WidgetType.scaffold) {
      if (slotName == 'appBar' && parent.appBar != null)
        return 'AppBar already exists.';
      if (slotName == 'bottomNavigationBar' &&
          parent.bottomNavigationBar != null)
        return 'BottomNavigationBar already exists.';
      if (slotName == 'floatingActionButton' &&
          parent.floatingActionButton != null)
        return 'FloatingActionButton already exists.';
      if (slotName == 'drawer' && parent.drawer != null)
        return 'Drawer already exists.';

      if (slotName == 'appBar')
        parent.appBar = child;
      else if (slotName == 'bottomNavigationBar')
        parent.bottomNavigationBar = child;
      else if (slotName == 'floatingActionButton')
        parent.floatingActionButton = child;
      else if (slotName == 'drawer')
        parent.drawer = child;

      _snapshot();
      state = cloned;
      return null;
    }

    // Validate parent relationship rules for regular children
    final validationError = child.type.validateParent(parent.type);
    if (validationError != null) return validationError;

    final error = parent.addChild(child);
    if (error != null) return error;

    _snapshot();
    state = cloned;
    return null;
  }

  void unwrapNode(String id) {
    _snapshot();
    final cloned = _deepCloneMap(state);

    // Cannot unwrap root
    for (final root in cloned.values) {
      if (root.id == id) return;
    }

    WidgetNode? parent;
    for (final root in cloned.values) {
      parent = _findParent(root, id);
      if (parent != null) break;
    }
    if (parent == null) return;

    WidgetNode? nodeToUnwrap;
    for (final root in cloned.values) {
      nodeToUnwrap = _findById(root, id);
      if (nodeToUnwrap != null) break;
    }
    if (nodeToUnwrap == null) return;

    final children = nodeToUnwrap.allDirectChildren;

    if (parent.child?.id == id) {
      if (children.length > 1)
        return; // Cannot unwrap multi-child into single-child parent
      parent.child = children.isEmpty ? null : children.first;
    } else {
      final idx = parent.children.indexWhere((c) => c.id == id);
      if (idx != -1) {
        parent.children.replaceRange(idx, idx + 1, children);
      }
    }
    state = cloned;
  }

  void moveNodeUp(String id) {
    _snapshot();
    final cloned = _deepCloneMap(state);
    WidgetNode? parent;
    for (final root in cloned.values) {
      if (root.id == id) return; // root
      parent = _findParent(root, id);
      if (parent != null) break;
    }
    if (parent == null || parent.children.isEmpty) return;

    final idx = parent.children.indexWhere((c) => c.id == id);
    if (idx > 0) {
      final temp = parent.children[idx - 1];
      parent.children[idx - 1] = parent.children[idx];
      parent.children[idx] = temp;
      state = cloned;
    }
  }

  void moveNodeDown(String id) {
    _snapshot();
    final cloned = _deepCloneMap(state);
    WidgetNode? parent;
    for (final root in cloned.values) {
      if (root.id == id) return; // root
      parent = _findParent(root, id);
      if (parent != null) break;
    }
    if (parent == null || parent.children.isEmpty) return;

    final idx = parent.children.indexWhere((c) => c.id == id);
    if (idx != -1 && idx < parent.children.length - 1) {
      final temp = parent.children[idx + 1];
      parent.children[idx + 1] = parent.children[idx];
      parent.children[idx] = temp;
      state = cloned;
    }
  }

  /// Remove node by id from the entire tree.
  void removeNode(String id) {
    _snapshot();
    final cloned = _deepCloneMap(state);

    for (final entry in cloned.entries) {
      if (entry.value.id == id) {
        // Trying to remove a root node natively?
        // We shouldn't do this via removeNode, but just in case:
        return;
      }
      if (_removeFromTree(entry.value, id)) {
        state = cloned;
        return;
      }
    }
  }

  /// Wrap [targetId] node with [wrapper]. After wrapping, target becomes wrapper's child.
  String? wrapNode(String targetId, WidgetNode wrapper) {
    _snapshot();
    final cloned = _deepCloneMap(state);

    for (final key in cloned.keys) {
      if (cloned[key]!.id == targetId) {
        wrapper.child = cloned[key];
        cloned[key] = wrapper;
        state = cloned;
        return null;
      }
    }

    for (final root in cloned.values) {
      final error = _wrapInTree(root, targetId, wrapper);
      if (error == null) {
        state = cloned;
        return null;
      }
    }
    return 'Target not found in tree.';
  }

  /// Move a node to a new parent in the tree.
  String? moveNode(
    String nodeId,
    String targetParentId, {
    int? insertIndex,
    String? slotName,
  }) {
    _snapshot();
    final cloned = _deepCloneMap(state);

    for (final root in cloned.values) {
      if (nodeId == root.id) return 'Cannot move a root widget.';
    }

    WidgetNode? nodeToMove;
    for (final root in cloned.values) {
      nodeToMove = _findById(root, nodeId);
      if (nodeToMove != null) break;
    }
    if (nodeToMove == null) return 'Node to move not found.';

    WidgetNode? targetParent;
    for (final root in cloned.values) {
      targetParent = _findById(root, targetParentId);
      if (targetParent != null) break;
    }
    if (targetParent == null) return 'Target parent not found.';

    // Prevent dragging a node into itself or its own descendants
    if (targetParentId == nodeId ||
        _findById(nodeToMove, targetParentId) != null) {
      return 'Cannot drop a widget into itself or its descendants.';
    }

    if (slotName != null && targetParent.type == WidgetType.scaffold) {
      if (slotName == 'appBar' && targetParent.appBar != null)
        return 'AppBar already exists.';
      if (slotName == 'bottomNavigationBar' &&
          targetParent.bottomNavigationBar != null)
        return 'BottomNavigationBar already exists.';
      if (slotName == 'floatingActionButton' &&
          targetParent.floatingActionButton != null)
        return 'FloatingActionButton already exists.';
      if (slotName == 'drawer' && targetParent.drawer != null)
        return 'Drawer already exists.';
    } else {
      // Regular capacity checks
      final capacityErr = nodeToMove.type.validateParent(targetParent.type);
      if (capacityErr != null) return capacityErr;

      // Special case: Scaffold body
      if (targetParent.isScaffold) {
        if (targetParent.child != null)
          return '${targetParent.type.displayName} already has a body.';
      } else {
        if (targetParent.isLeaf)
          return '${targetParent.type.displayName} cannot have children.';
        if (targetParent.isSingleChild && targetParent.child != null)
          return '${targetParent.type.displayName} already has a child.';
      }
    }

    // Detach from old parent
    for (final root in cloned.values) {
      final oldParent = _findParent(root, nodeId);
      if (oldParent != null) {
        oldParent.removeChildById(nodeId);
        break;
      }
    }

    // Attach to new parent
    if (slotName != null && targetParent.type == WidgetType.scaffold) {
      if (slotName == 'appBar')
        targetParent.appBar = nodeToMove;
      else if (slotName == 'bottomNavigationBar')
        targetParent.bottomNavigationBar = nodeToMove;
      else if (slotName == 'floatingActionButton')
        targetParent.floatingActionButton = nodeToMove;
      else if (slotName == 'drawer')
        targetParent.drawer = nodeToMove;
    } else if (targetParent.isMultiChild) {
      if (insertIndex != null &&
          insertIndex >= 0 &&
          insertIndex <= targetParent.children.length) {
        targetParent.children.insert(insertIndex, nodeToMove);
      } else {
        targetParent.children.add(nodeToMove);
      }
    } else {
      targetParent.child = nodeToMove;
    }

    state = cloned;
    return null;
  }

  /// Move a node up/down in its parent's children list
  void reorderChild(String parentId, int oldIndex, int newIndex) {
    _snapshot();
    final cloned = _deepCloneMap(state);
    WidgetNode? parent;
    for (final root in cloned.values) {
      parent = _findById(root, parentId);
      if (parent != null) break;
    }
    if (parent == null || !parent.isMultiChild) return;
    final item = parent.children.removeAt(oldIndex);
    parent.children.insert(newIndex, item);
    state = cloned;
  }

  void updateProps(String id, String key, dynamic value) {
    updateNode(id, (node) {
      node.props.set(key, value);
    });
  }

  void renameNode(String id, String newLabel) {
    updateNode(id, (node) => node.label = newLabel);
  }

  void loadProject(ProjectModel project) {
    _history.clear();
    if (project.screens != null && project.screens!.isNotEmpty) {
      state = project.screens!;
    } else if (project.root != null) {
      // Backwards compatibility with single screen format
      state = {project.screenName: project.root!};
    } else {
      state = {'HomeScreen': WidgetNode(type: WidgetType.scaffold)};
    }
  }

  // ── History ─────────────────────────────────────────────────────────────
  void _snapshot() {
    _history.push(state);
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  void undo() {
    final prev = _history.undo(state);
    if (prev != null) state = _deepCloneMap(prev.value);
  }

  void redo() {
    final next = _history.redo(state);
    if (next != null) state = _deepCloneMap(next.value);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Map<String, WidgetNode> _deepCloneMap(Map<String, WidgetNode> map) {
    return map.map((k, v) => MapEntry(k, v.exactClone()));
  }

  WidgetNode? _findById(WidgetNode node, String id) {
    if (node.id == id) return node;
    for (final c in node.allDirectChildren) {
      final found = _findById(c, id);
      if (found != null) return found;
    }
    return null;
  }

  WidgetNode? _findParent(WidgetNode current, String childId) {
    for (final c in current.allDirectChildren) {
      if (c.id == childId) return current;
      final found = _findParent(c, childId);
      if (found != null) return found;
    }
    return null;
  }

  bool _removeFromTree(WidgetNode node, String id) {
    if (node.removeChildById(id)) return true;
    for (final c in node.allDirectChildren) {
      if (_removeFromTree(c, id)) return true;
    }
    return false;
  }

  String? _wrapInTree(WidgetNode node, String targetId, WidgetNode wrapper) {
    // Check children list
    final idx = node.children.indexWhere((c) => c.id == targetId);
    if (idx != -1) {
      final target = node.children[idx];
      wrapper.child = target;
      node.children[idx] = wrapper;
      return null;
    }
    // Check single child
    if (node.child?.id == targetId) {
      final target = node.child!;
      wrapper.child = target;
      node.child = wrapper;
      return null;
    }
    // Recurse
    for (final c in node.allDirectChildren) {
      final err = _wrapInTree(c, targetId, wrapper);
      if (err == null) return null;
    }
    return 'Target not found in tree.';
  }
}

final widgetTreeProvider =
    NotifierProvider<WidgetTreeNotifier, Map<String, WidgetNode>>(() {
      return WidgetTreeNotifier();
    });

// ── Selected node ────────────────────────────────────────────────────────────
final selectedNodeIdProvider = StateProvider<String?>((ref) => null);

// ── Canvas size ──────────────────────────────────────────────────────────────
final canvasSizeProvider = StateProvider<(double, double)>((ref) => (390, 844));

// ── UI state ─────────────────────────────────────────────────────────────────
final showCodePanelProvider = StateProvider<bool>((ref) => false);
