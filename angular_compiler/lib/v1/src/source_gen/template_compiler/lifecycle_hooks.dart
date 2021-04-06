import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';

final Map<TypeChecker, LifecycleHooks> _hooks = <TypeChecker, LifecycleHooks>{
  const TypeChecker.fromUrl('$lifecycleHooksUrl#OnInit'): LifecycleHooks.onInit,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#OnDestroy'):
      LifecycleHooks.onDestroy,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#DoCheck'):
      LifecycleHooks.doCheck,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#AfterChanges'):
      LifecycleHooks.afterChanges,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#AfterContentInit'):
      LifecycleHooks.afterContentInit,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#AfterContentChecked'):
      LifecycleHooks.afterContentChecked,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#AfterViewInit'):
      LifecycleHooks.afterViewInit,
  const TypeChecker.fromUrl('$lifecycleHooksUrl#AfterViewChecked'):
      LifecycleHooks.afterViewChecked,
};

List<LifecycleHooks> extractLifecycleHooks(ClassElement clazz) {
  return _hooks.keys
      .where((hook) => hook.isAssignableFrom(clazz))
      .map((t) => _hooks[t])
      .toList();
}
