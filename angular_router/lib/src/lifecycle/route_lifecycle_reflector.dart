import '../interfaces.dart';
import 'lifecycle_annotations.dart';

bool hasLifecycleHook(RouteLifecycleHook e, instance) {
  if (e == routerOnActivate) {
    return instance is OnActivate;
  } else if (e == routerOnDeactivate) {
    return instance is OnDeactivate;
  } else if (e == routerOnReuse) {
    return instance is OnReuse;
  } else if (e == routerCanDeactivate) {
    return instance is CanDeactivate;
  } else if (e == routerCanReuse) {
    return instance is CanReuse;
  }
  return false;
}
