import 'package:meta/meta.dart';

import 'providers.dart';

/// Encapsulates a reusable set of dependency injection configurations.
///
/// One or more modules can be used to create an [Injector], or a runtime
/// representation of dependency injection. Modules can also be used to add
/// dependency injection to `@Directive` or `@Component`-annotated classes.
///
/// Other modules are included ([include]) before providers ([provide]).
///
/// Previously, AngularDart loosely expressed "modules" as a recursive list of
/// both providers and other lists of providers. For example, the following
/// pattern may be re-written to use `Module`:
/// ```dart
/// // Before.
/// const carModule = [
///   ClassProvider(Car, useClass: AmericanCar),
/// ];
///
/// const autoShopModule = [
///   carModule,
///   ClassProvider(Oil, useClass: GenericOil),
/// ];
///
/// // After.
/// const carModule = Module(
///   provide: [
///     ClassProvider(Car, useClass: AmericanCar),
///   ],
/// );
///
/// const autoShopModule = Module(
///   include: [
///     carModule,
///   ],
///   provide: [
///     ClassProvider(Oil, useClass: GenericOil),
///   ],
/// );
/// ```
class Module {
  final List<Module> include;
  final List<Provider<Object>> provide;

  @literal
  const factory Module({
    List<Module> include,
    List<Provider<Object>> provide,
  }) = Module._;

  const Module._({
    this.include = const [],
    this.provide = const [],
  });
}

/// Compatibility layer for expressing a [Module] as a `List<...>`.
///
/// **DO NOT USE**: This function may break or change at any time.
List<Provider<Object>> internalModuleToList(Module module) {
  final result = <Provider<Object>>[];
  final includes = module.include;
  for (var i = 0, l = includes.length; i < l; i++) {
    result.addAll(internalModuleToList(includes[i]));
  }
  final provides = module.provide;
  for (var i = 0, l = provides.length; i < l; i++) {
    result.add(provides[i]);
  }
  return result;
}
