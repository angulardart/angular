/// Maps application URLs into application states, to support deep-linking and
/// navigation.
library angular_router;

export 'src/constants.dart'
    show
        routerDirectives,
        routerProviders,
        routerProvidersHash,
        routerModule,
        routerHashModule;
export 'src/directives/router_link_active_directive.dart' show RouterLinkActive;
export 'src/directives/router_link_directive.dart' show RouterLink;
export 'src/directives/router_outlet_directive.dart' show RouterOutlet;
export 'src/lifecycle.dart';
export 'src/location.dart';
export 'src/route_definition.dart' show RouteDefinition;
export 'src/route_path.dart' show RoutePath;
export 'src/router/navigation_params.dart' show NavigationParams;
export 'src/router/router.dart' show Router, NavigationResult;
export 'src/router/router_state.dart' show RouterState;
export 'src/router_hook.dart' show RouterHook;
