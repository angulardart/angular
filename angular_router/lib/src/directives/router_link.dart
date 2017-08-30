import 'dart:html' show MouseEvent;

import 'package:angular/angular.dart' show Directive, Input, Visibility;

import '../instruction.dart' show Instruction;
import '../location.dart' show Location;
import '../router.dart' show Router;

/// The RouterLink directive lets you link to specific parts of your app.
///
/// Consider the following route configuration:
///
/// <?code-excerpt "docs/toh-5/lib/app_component.dart (heroes)"?>
/// ```dart
/// @RouteConfig(const [
///   const Route(path: '/heroes', name: 'Heroes', component: HeroesComponent)
/// ])
/// ```
///
/// When linking to this `Heroes` route, you can write:
///
/// <?code-excerpt "docs/toh-5/lib/app_component_1.dart (template-v2)"?>
/// ```dart
/// template: '''
///   <h1>{{title}}</h1>
///   <a [routerLink]="['Heroes']">Heroes</a>
///   <router-outlet></router-outlet>''',
/// ```
///
/// RouterLink expects the value to be an array of route names, followed by the params
/// for that level of routing. For instance `['/Team', {teamId: 1}, 'User', {userId: 2}]`
/// means that we want to generate a link for the `Team` route with params `{teamId: 1}`,
/// and with a child route `User` with params `{userId: 2}`.
///
/// The first route name should be prepended with `/`, `./`, or `../`.
/// If the route begins with `/`, the router will look up the route from the root of the app.
/// If the route begins with `./`, the router will instead look in the current component's
/// children for the route. And if the route begins with `../`, the router will look at the
/// current component's parent.
@Directive(
  selector: "[routerLink]",
  host: const {
    "(click)": "onClick(\$event)",
    "[attr.href]": "visibleHref",
    "[class.router-link-active]": "isRouteActive"
  },
  visibility: Visibility.none,
)
class RouterLink {
  Router _router;
  Location _location;
  List<dynamic> _routeParams;
  // the url displayed on the anchor element.
  String visibleHref;
  @Input()
  String target;
  // the instruction passed to the router to navigate
  Instruction _navigationInstruction;
  RouterLink(this._router, this._location) {
    // we need to update the link whenever a route changes to account for aux routes
    this._router.subscribe((_) => this._updateLink());
  }
  // because auxiliary links take existing primary and auxiliary routes into account,

  // we need to update the link whenever params or other routes change.
  void _updateLink() {
    this._navigationInstruction = this._router.generate(this._routeParams);
    var navigationHref = this._navigationInstruction.toLinkUrl();
    this.visibleHref = this._location.prepareExternalUrl(navigationHref);
  }

  bool get isRouteActive {
    return this._router.isRouteActive(this._navigationInstruction);
  }

  @Input('routerLink')
  set routeParams(List<dynamic> changes) {
    this._routeParams = changes;
    this._updateLink();
  }

  void onClick(MouseEvent event) {
    // If any "open in new window" modifier is present, use default browser
    // behavior
    if (event.button != 0 || event.ctrlKey || event.metaKey) {
      return;
    }

    // If target is present and not _self, use default browser behavior
    if (this.target is String && this.target != "_self") {
      return;
    }

    this._router.navigateByInstruction(this._navigationInstruction);
    event.preventDefault();
  }
}
