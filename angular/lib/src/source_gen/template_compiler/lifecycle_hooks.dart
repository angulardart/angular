import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/core/metadata.dart';

List<LifecycleHooks> extractLifecycleHooks(ClassElement clazz) {
  const hooks = <TypeChecker, LifecycleHooks>{
    TypeChecker.fromRuntime(OnInit): LifecycleHooks.onInit,
    TypeChecker.fromRuntime(OnDestroy): LifecycleHooks.onDestroy,
    TypeChecker.fromRuntime(DoCheck): LifecycleHooks.doCheck,
    TypeChecker.fromRuntime(AfterChanges): LifecycleHooks.afterChanges,
    TypeChecker.fromRuntime(AfterContentInit): LifecycleHooks.afterContentInit,
    TypeChecker.fromRuntime(AfterContentChecked):
        LifecycleHooks.afterContentChecked,
    TypeChecker.fromRuntime(AfterViewInit): LifecycleHooks.afterViewInit,
    TypeChecker.fromRuntime(AfterViewChecked): LifecycleHooks.afterViewChecked,
  };
  return hooks.keys
      .where((hook) => hook.isAssignableFrom(clazz))
      .map((t) => hooks[t])
      .toList();
}
