import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';

final _typeCheckerToLifecycleHook = {
  $OnInit: LifecycleHooks.onInit,
  $OnDestroy: LifecycleHooks.onDestroy,
  $DoCheck: LifecycleHooks.doCheck,
  $AfterChanges: LifecycleHooks.afterChanges,
  $AfterContentInit: LifecycleHooks.afterContentInit,
  $AfterContentChecked: LifecycleHooks.afterContentChecked,
  $AfterViewInit: LifecycleHooks.afterViewInit,
  $AfterViewChecked: LifecycleHooks.afterViewChecked,
};

List<LifecycleHooks> extractLifecycleHooks(ClassElement element) {
  return _typeCheckerToLifecycleHook.keys
      .where((typeChecker) => typeChecker.isAssignableFrom(element))
      .map((typeChecker) => _typeCheckerToLifecycleHook[typeChecker]!)
      .toList();
}
