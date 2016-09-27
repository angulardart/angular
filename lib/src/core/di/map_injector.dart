import "injector.dart" show Injector, InjectorFactory, THROW_IF_NOT_FOUND;

/// A simple injector based on a Map of values.
class MapInjector implements Injector {
  Injector _parent;
  static InjectorFactory<dynamic> createFactory(
      [Map<dynamic, dynamic> values]) {
    return new MapInjectorFactory(values);
  }

  Map<dynamic, dynamic> _values;
  MapInjector([this._parent = null, Map<dynamic, dynamic> values = null]) {
    if (values == null) {
      values = new Map<dynamic, dynamic>();
    }
    this._values = values;
    if (_parent == null) {
      this._parent = Injector.NULL;
    }
  }
  dynamic get(dynamic token, [dynamic notFoundValue = THROW_IF_NOT_FOUND]) {
    if (identical(token, Injector)) {
      return this;
    }
    if (this._values.containsKey(token)) {
      return this._values[token];
    }
    return this._parent.get(token, notFoundValue);
  }
}

/// InjectorFactory for MapInjector.
class MapInjectorFactory implements InjectorFactory<dynamic> {
  Map<dynamic, dynamic> _values;
  MapInjectorFactory([this._values = null]);
  Injector create([Injector parent = null, dynamic context = null]) {
    return new MapInjector(parent, this._values);
  }
}
