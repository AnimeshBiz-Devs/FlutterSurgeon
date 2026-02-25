class HistoryEntry<T> {
  final T value;
  HistoryEntry(this.value);
}

class HistoryManager<T> {
  final List<HistoryEntry<T>> _undo = [];
  final List<HistoryEntry<T>> _redo = [];
  final T Function(T) _clone;
  static const int _maxDepth = 50;

  HistoryManager({required T Function(T) clone}) : _clone = clone;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(T state) {
    _undo.add(HistoryEntry(_clone(state)));
    if (_undo.length > _maxDepth) _undo.removeAt(0);
    _redo.clear();
  }

  HistoryEntry<T>? undo(T current) {
    if (!canUndo) return null;
    _redo.add(HistoryEntry(_clone(current)));
    return _undo.removeLast();
  }

  HistoryEntry<T>? redo(T current) {
    if (!canRedo) return null;
    _undo.add(HistoryEntry(_clone(current)));
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
