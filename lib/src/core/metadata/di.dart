import "package:angular2/src/core/di/metadata.dart" show DependencyMetadata;

class AttributeMetadata extends DependencyMetadata {
  final String attributeName;
  const AttributeMetadata(this.attributeName) : super();
  AttributeMetadata get token {
    // Normally one would default a token to a type of an injected value but
    // here the type of a variable is "string" and we can't use primitive type
    // as a return value so we use instance of Attribute instead. This doesn't
    // matter much in practice as arguments with @Attribute annotation are
    // injected by ElementInjector that doesn't take tokens into account.
    return this;
  }

  String toString() {
    return '@Attribute($attributeName)';
  }
}

class QueryMetadata extends DependencyMetadata {
  final dynamic /* Type | String */ selector;

  /// whether we want to query only direct children (false) or all children
  /// (true).
  final bool descendants;
  final bool first;

  /// The DI token to read from an element that matches the selector.
  final dynamic read;
  const QueryMetadata(this.selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : descendants = descendants,
        first = first,
        read = read,
        super();

  /// Always `false` to differentiate it with [ViewQueryMetadata].
  bool get isViewQuery => false;

  /// Whether this is querying for a variable binding or a directive.
  bool get isVarBindingQuery => selector is String;

  /// A list of variable bindings this is querying for.
  ///
  /// Only applicable if this is a variable bindings query.
  List get varBindings => selector.split(',');

  String toString() => '@Query($selector)';
}
// TODO: add an example after ContentChildren and ViewChildren are in master

class ContentChildrenMetadata extends QueryMetadata {
  const ContentChildrenMetadata(dynamic /* Type | String */ _selector,
      {bool descendants: false, dynamic read: null})
      : super(_selector, descendants: descendants, read: read);
}
// TODO: add an example after ContentChild and ViewChild are in master

class ContentChildMetadata extends QueryMetadata {
  const ContentChildMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
}

class ViewQueryMetadata extends QueryMetadata {
  const ViewQueryMetadata(dynamic /* Type | String */ _selector,
      {bool descendants: false, bool first: false, dynamic read: null})
      : super(_selector, descendants: descendants, first: first, read: read);

  /// Always `true` to differentiate it with [QueryMetadata].
  get isViewQuery => true;

  String toString() => '@ViewQuery($selector)';
}

class ViewChildrenMetadata extends ViewQueryMetadata {
  const ViewChildrenMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, read: read);
}

class ViewChildMetadata extends ViewQueryMetadata {
  const ViewChildMetadata(dynamic /* Type | String */ _selector,
      {dynamic read: null})
      : super(_selector, descendants: true, first: true, read: read);
}

class ProviderPropertyMetadata {
  final dynamic token;
  final bool _multi;
  const ProviderPropertyMetadata(this.token, {bool multi: false})
      : _multi = multi;
  bool get multi {
    return this._multi;
  }
}

class InjectorModuleMetadata {
  final List<dynamic> _providers;
  const InjectorModuleMetadata({List<dynamic> providers: const []})
      : _providers = providers;
  List<dynamic> get providers {
    return this._providers;
  }
}
