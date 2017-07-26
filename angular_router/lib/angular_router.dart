/// Maps application URLs into application states, to support deep-linking and
/// navigation.
library angular_router;

import 'src/directives/router_link.dart' show RouterLink;
import 'src/directives/router_outlet.dart' show RouterOutlet;

export 'src/directives/router_link.dart' show RouterLink;
export 'src/directives/router_outlet.dart' show RouterOutlet;
export 'src/instruction.dart'
    show Instruction, ComponentInstruction, RouteParams, RouteData;
export 'src/interfaces.dart'
    show OnActivate, OnDeactivate, OnReuse, CanDeactivate, CanReuse;
export 'src/lifecycle/lifecycle_annotations.dart' show CanActivate;
export 'src/location.dart';
export 'src/route_config/route_config_decorator.dart';
export 'src/route_definition.dart';
export 'src/route_registry.dart' show RouteRegistry, ROUTER_PRIMARY_COMPONENT;
export 'src/router.dart' show Router;
export 'src/router_providers.dart' show ROUTER_PROVIDERS, ROUTER_BINDINGS;
export 'src/router_providers_common.dart' show ROUTER_PROVIDERS_COMMON;

/// A list of directives. To use the router directives like [RouterOutlet] and
/// [RouterLink], add this to your `directives` array in the [View] decorator of
/// your component.
///
/// ## Example ([live demo](http://plnkr.co/edit/iRUP8B5OUbxCWQ3AcIDm))
///
/// ```
/// import 'package:angular/angular.dart' show Component;
/// import 'package:angular_router/angular_router.dart'
///     show ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig;
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
