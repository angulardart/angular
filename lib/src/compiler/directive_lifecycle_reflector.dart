import 'package:angular2/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular2/src/core/reflection/reflection.dart';

const INTERFACES = const {
  LifecycleHooks.OnInit: OnInit,
  LifecycleHooks.OnDestroy: OnDestroy,
  LifecycleHooks.DoCheck: DoCheck,
  LifecycleHooks.OnChanges: OnChanges,
  LifecycleHooks.AfterContentInit: AfterContentInit,
  LifecycleHooks.AfterContentChecked: AfterContentChecked,
  LifecycleHooks.AfterViewInit: AfterViewInit,
  LifecycleHooks.AfterViewChecked: AfterViewChecked,
};

bool hasLifecycleHook(LifecycleHooks interface, token) {
  if (token is! Type) return false;
  Type interfaceType = INTERFACES[interface];
  return reflector.interfaces(token).contains(interfaceType);
}
