/// Maps application URLs into application states, to support deep-linking and
/// navigation.
library angular2.router;

import "src/router/directives/router_link.dart" show RouterLink;
import "src/router/directives/router_outlet.dart" show RouterOutlet;

export "package:angular2/core.dart" show OpaqueToken;
export "package:angular2/src/router/router_providers.dart"
    show ROUTER_PROVIDERS, ROUTER_BINDINGS;
export "package:angular2/src/router/router_providers_common.dart"
    show ROUTER_PROVIDERS_COMMON;

export "src/router/directives/router_link.dart" show RouterLink;
export "src/router/directives/router_outlet.dart" show RouterOutlet;
export "src/router/instruction.dart" show RouteParams, RouteData;
export "src/router/instruction.dart" show Instruction, ComponentInstruction;
export "src/router/interfaces.dart"
    show OnActivate, OnDeactivate, OnReuse, CanDeactivate, CanReuse;
export "src/router/lifecycle/lifecycle_annotations.dart" show CanActivate;
export "src/router/route_config/route_config_decorator.dart";
export "src/router/route_definition.dart";
export "src/router/route_registry.dart"
    show RouteRegistry, ROUTER_PRIMARY_COMPONENT;
export "src/router/router.dart" show Router;

/// A list of directives. To use the router directives like [RouterOutlet] and
/// [RouterLink], add this to your `directives` array in the [View] decorator of
/// your component.
///
/// ## Example ([live demo](http://plnkr.co/edit/iRUP8B5OUbxCWQ3AcIDm))
///
/// ```
/// import 'package:angular2/cored.dart' show Component;
/// import 'package:angular2/router.dart'
///     show ROUTER_DIRECTIVES, ROUTER_PROVIERS, RouteConfig;
///
/// @Component(directives: const [ROUTER_DIRECTIVES])
/// @RouteConfig(const [
///  {...},
/// ])
/// class AppCmp {
///    // ...
/// }
///
/// bootstrap(AppCmp, [ROUTER_PROVIDERS]);
/// ```
const List<dynamic> ROUTER_DIRECTIVES = const [RouterOutlet, RouterLink];
