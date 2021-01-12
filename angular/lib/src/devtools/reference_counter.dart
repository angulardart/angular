import 'error.dart';

/// A reference counter used to keep objects alive between requests.
class ReferenceCounter<T> {
  /// Maps a group name to the set of references retained by that group.
  final _groups = <String, Set<_Reference<T>>>{};

  /// Maps a unique ID to a reference counted object.
  final _idToReference = <int, _Reference<T>>{};

  /// Maps an object by identity to its unique ID.
  final _objectToId = Map<T, int>.identity();

  /// A counter used to generate unique IDs for [toId].
  var _nextId = 0;

  /// Frees all object references.
  ///
  /// Only use this method in tests to ensure that object references from one
  /// test case don't affect another.
  void dispose() {
    _groups.clear();
    _idToReference.clear();
    _objectToId.clear();
    _nextId = 0;
  }

  /// Frees all object references held by a group.
  ///
  /// The objects may be kept alive by references from another group.
  void disposeGroup(String groupName) {
    final references = _groups.remove(groupName);
    if (references == null) {
      return;
    }
    for (final reference in references) {
      reference.count -= 1;
      if (reference.count == 0) {
        final id = _objectToId.remove(reference.object);
        assert(id != null);
        _idToReference.remove(id);
      }
    }
  }

  /// Returns a unique ID for an [object] and retains it.
  ///
  /// The object is kept alive at least until [disposeGroup] is called on
  /// [groupName].
  int toId(T object, String groupName) {
    final group = _groups[groupName] ??= Set.identity();

    var id = _objectToId[object];
    if (id == null) {
      // Retain the object.
      id = _nextId++;
      _objectToId[object] = id;
      final reference = _Reference(object);
      _idToReference[id] = reference;
      group.add(reference);
    } else {
      // Increment reference count if not already retained by the group.
      final reference = _idToReference[id]!;
      if (group.add(reference)) {
        reference.count += 1;
      }
    }

    return id;
  }

  /// Returns the object associated with [id].
  T toObject(int id) {
    final reference = _idToReference[id];
    if (reference == null) {
      throw DevToolsError('ID does not exist: $id');
    }

    return reference.object;
  }
}

/// A reference counted object.
class _Reference<T> {
  _Reference(this.object);

  /// The object being reference counted.
  final T object;

  /// The number of references to [object].
  var count = 1;
}
