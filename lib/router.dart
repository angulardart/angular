/**
 * 
 * 
 * Maps application URLs into application states, to support deep-linking and navigation.
 */
library angular2.router;

export "src/router/router.dart" show Router;
export "src/router/directives/router_outlet.dart" show RouterOutlet;
export "src/router/directives/router_link.dart" show RouterLink;
export "src/router/instruction.dart" show RouteParams, RouteData;
export "src/router/route_registry.dart"
    show RouteRegistry, ROUTER_PRIMARY_COMPONENT;
export "src/router/route_config/route_config_decorator.dart";
export "src/router/route_definition.dart";
export "src/router/interfaces.dart"
    show OnActivate, OnDeactivate, OnReuse, CanDeactivate, CanReuse;
export "src/router/lifecycle/lifecycle_annotations.dart" show CanActivate;
export "src/router/instruction.dart" show Instruction, ComponentInstruction;
export "package:angular2/core.dart" show OpaqueToken;
export "package:angular2/src/router/router_providers_common.dart"
    show ROUTER_PROVIDERS_COMMON;
export "package:angular2/src/router/router_providers.dart"
    show ROUTER_PROVIDERS, ROUTER_BINDINGS;
import "src/router/directives/router_outlet.dart" show RouterOutlet;
import "src/router/directives/router_link.dart" show RouterLink;

/**
 * A list of directives. To use the router directives like [RouterOutlet] and
 * [RouterLink], add this to your `directives` array in the [View] decorator of your
 * component.
 *
 * ### Example ([live demo](http://plnkr.co/edit/iRUP8B5OUbxCWQ3AcIDm))
 *
 * ```
 * import {Component} from 'angular2/core';
 * import {ROUTER_DIRECTIVES, ROUTER_PROVIDERS, RouteConfig} from 'angular2/router';
 *
 * @Component({directives: [ROUTER_DIRECTIVES]})
 * @RouteConfig([
 *  {...},
 * ])
 * class AppCmp {
 *    // ...
 * }
 *
 * bootstrap(AppCmp, [ROUTER_PROVIDERS]);
 * ```
 */
const List<dynamic> ROUTER_DIRECTIVES = const [RouterOutlet, RouterLink];
