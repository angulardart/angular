import "package:angular2/core.dart" show Directive;
import "package:angular2/platform/common.dart" show Location;

import "../instruction.dart" show Instruction;
import "../router.dart" show Router;

/// The RouterLink directive lets you link to specific parts of your app.
///
/// Consider the following route configuration:
///
/// {@example docs/toh-5/lib/app_component.dart region=heroes}
///
/// When linking to this `Heroes` route, you can write:
///
/// {@example docs/toh-5/lib/app_component_1.dart region=template-v2}
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
@Directive(selector: "[routerLink]", inputs: const [
  "routeParams: routerLink",
  "target: target"
], host: const {
  "(click)": "onClick()",
  "[attr.href]": "visibleHref",
  "[class.router-link-active]": "isRouteActive"
})
class RouterLink {
  Router _router;
  Location _location;
  List<dynamic> _routeParams;
  // the url displayed on the anchor element.
  String visibleHref;
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

  set routeParams(List<dynamic> changes) {
    this._routeParams = changes;
    this._updateLink();
  }

  bool onClick() {
    // If no target, or if target is _self, prevent default browser behavior
    if (this.target is! String || this.target == "_self") {
      this._router.navigateByInstruction(this._navigationInstruction);
      return false;
    }
    return true;
  }
}
