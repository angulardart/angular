import 'dart:async';

/// Immutable map of parameters for the given route
/// based on the url matcher and optional parameters for that route.
///
/// You can inject [RouteParams] into the constructor of a component to use it.
///
/// ### Example
///
/// import 'package:angular/angular.dart';
/// import 'package:angular/platform/browser.dart';
/// import 'package:angular/router.dart';
///
/// @Component(directives: [ROUTER_DIRECTIVES])
/// @RouteConfig(const [
/// {'path': '/user/:id', 'component': UserCmp, 'name': 'UserCmp'},
/// ])
/// class AppCmp {}
///
/// @Component( template: 'user: {{id}}' )
/// class UserCmp {
///   String id;
///   UserCmp(RouteParams params) {
///     id = params.get('id');
///   }
/// }
///
/// bootstrap(AppCmp, ROUTER_PROVIDERS);
class RouteParams {
  Map<String, String> params;
  RouteParams(this.params);
  String get(String param) => params[param];
}

/// `RouteData` is an immutable map of additional data you can configure in your
/// [Route].
///
/// You can inject `RouteData` into the constructor of a component to use it.
///
/// ### Example
///
/// import 'package:angular/angular.dart';
/// import 'package:angular/platform/browser.dart';
/// import 'package:angular/router.dart';
///
/// @Component(directives: [ROUTER_DIRECTIVES])
/// @RouteConfig(const [
///  {'path': '/user/:id', 'component': UserCmp, 'name': 'UserCmp',
///  'data': {'isAdmin': true}},
/// ])
/// class AppCmp {}
///
/// @Component(
///   ...,
///   template: 'user: {{isAdmin}}'
/// )
/// class UserCmp {
///   String isAdmin;
///   UserCmp(RouteData data) {
///     isAdmin = data.get('isAdmin');
///   }
/// }
///
/// bootstrap(AppCmp, ROUTER_PROVIDERS);
class RouteData {
  final Map<String, dynamic> data;
  const RouteData([this.data = const {}]);
  dynamic get(String key) => data[key];
}

const BLANK_ROUTE_DATA = const RouteData();

/// [Instruction] is a tree of [ComponentInstruction]s with all the information
/// needed to transition each component in the app to a given route,
/// including all auxiliary routes.
///
/// [Instruction]s can be created using [Router#generate], and can be used to
/// perform route changes with [Router#navigateByInstruction].
///
/// ### Example
///
/// import 'package:angular/angular.dart';
/// import 'package:angular/platform/browser.dart';
/// import 'package:angular/router.dart';
///
/// @Component(directives: [ROUTER_DIRECTIVES])
/// @RouteConfig(const [
///  {...},
/// ])
/// class AppCmp {
///   AppCmp(Router router) {
///     var instruction = router.generate(['/MyRoute']);
///     router.navigateByInstruction(instruction);
///   }
/// }
///
/// bootstrap(AppCmp, ROUTER_PROVIDERS);
///
abstract class Instruction {
  ComponentInstruction component;
  Instruction child;
  Map<String, Instruction> auxInstruction;

  Instruction(this.component, this.child, this.auxInstruction);

  String get urlPath => component?.urlPath ?? '';

  List<String> get urlParams => component?.urlParams ?? [];

  String get specificity {
    var total = '';
    if (component != null) {
      total += component.specificity;
    }
    if (child != null) {
      total += child.specificity;
    }
    return total;
  }

  Future<ComponentInstruction> resolveComponent();

  /// Converts the instruction into a URL string.
  String get rootUrl => path + toUrlQuery();

  String _toNonRootUrl() {
    return this._stringifyPathMatrixAuxPrefixed() +
        (child?._toNonRootUrl() ?? '');
  }

  String toUrlQuery() {
    return urlParams.isNotEmpty ? ('?' + urlParams.join('&')) : '';
  }

  /// Returns a new instruction that shares the state of the existing
  /// instruction, but with the given child [Instruction] replacing the existing
  /// child.
  Instruction replaceChild(Instruction child) =>
      new ResolvedInstruction(component, child, auxInstruction);

  /// If the final URL for the instruction is ``.
  String get path => urlPath + _stringifyAux() + (child?._toNonRootUrl() ?? '');

  @Deprecated('Please use path property getter')
  String toUrlPath() => path;

  // default instructions override these.
  String toLinkUrl() {
    return urlPath +
        _stringifyAux() +
        (child?._toLinkUrl() ?? '') +
        toUrlQuery();
  }
  // this is the non-root version (called recursively)

  String _toLinkUrl() {
    return _stringifyPathMatrixAuxPrefixed() + (child?._toLinkUrl() ?? '');
  }

  String _stringifyPathMatrixAuxPrefixed() {
    var primary = _stringifyPathMatrixAux();
    if (primary.length > 0) {
      primary = '/' + primary;
    }
    return primary;
  }

  String _stringifyMatrixParams() {
    return urlParams.isNotEmpty ? (';' + urlParams.join(';')) : '';
  }

  String _stringifyPathMatrixAux() {
    if (component == null) return '';
    return urlPath + _stringifyMatrixParams() + _stringifyAux();
  }

  String _stringifyAux() {
    var routes = [];
    for (Instruction auxInstruction in auxInstruction.values) {
      routes.add(auxInstruction._stringifyPathMatrixAux());
    }
    if (routes.length > 0) {
      return '(' + routes.join('//') + ')';
    }
    return '';
  }
}

/// A resolved instruction has an outlet instruction for itself, but maybe not
/// for...
class ResolvedInstruction extends Instruction {
  ResolvedInstruction(ComponentInstruction component, Instruction child,
      Map<String, Instruction> auxInstruction)
      : super(component, child, auxInstruction);

  Future<ComponentInstruction> resolveComponent() =>
      new Future.value(component);
}

/// Represents a resolved default route.
class DefaultInstruction extends ResolvedInstruction {
  DefaultInstruction(ComponentInstruction component, DefaultInstruction child)
      : super(component, child, {});

  String toLinkUrl() => '';

  String _toLinkUrl() => '';
}

/// Represents a component that may need to do some redirection or lazy loading
/// at a later time.
class UnresolvedInstruction extends Instruction {
  final /* () => Promise<Instruction> */ _resolver;
  final String _urlPath;
  final List<String> _urlParams;

  UnresolvedInstruction(this._resolver,
      [this._urlPath = '', this._urlParams = const []])
      : super(null, null, {});

  String get urlPath {
    if (component != null) return component.urlPath;
    if (_urlPath != null) return _urlPath;
    return '';
  }

  List<String> get urlParams {
    if (component != null) return component.urlParams;
    if (_urlParams != null) return _urlParams;
    return [];
  }

  String _stringifyPathMatrixAux() {
    if (urlPath.isEmpty) return '';
    return urlPath + _stringifyMatrixParams() + _stringifyAux();
  }

  Future<ComponentInstruction> resolveComponent() async {
    if (component != null) {
      return new Future<ComponentInstruction>.value(component);
    }
    Instruction instruction = await _resolver();
    child = instruction?.child;
    return component = instruction?.component;
  }
}

class RedirectInstruction extends ResolvedInstruction {
  final String _specificity;
  RedirectInstruction(ComponentInstruction component, Instruction child,
      Map<String, Instruction> auxInstruction, this._specificity)
      : super(component, child, auxInstruction);
  String get specificity {
    return this._specificity;
  }
}

/// Route state for a single component.
///
/// Instances of [ComponentInstruction] are passed to route lifecycle hooks,
/// like [CanActivate].
///
/// [ComponentInstruction] is a public API.
///
/// [ComponentInstruction]`s are [hash consed]
/// (https://en.wikipedia.org/wiki/Hash_consing). You should
/// never construct one yourself with 'new.' Instead, rely on router's internal
/// recognizer to construct.
///
/// You should not modify this object. It should be treated as immutable.
class ComponentInstruction {
  String urlPath;
  List<String> urlParams;
  var componentType;
  bool terminal;
  String specificity;
  Map<String, String> params;
  String routeName;
  bool reuse = false;
  RouteData routeData;

  ComponentInstruction(this.urlPath, this.urlParams, RouteData data,
      this.componentType, this.terminal, this.specificity,
      [this.params, this.routeName]) {
    this.routeData = data ?? BLANK_ROUTE_DATA;
  }
}
