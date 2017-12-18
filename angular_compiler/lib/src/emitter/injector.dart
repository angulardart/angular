import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

import '../analyzer/di/injector.dart';

/// Generates `.dart` source code given a list of providers to bind.
///
/// **NOTE**: This class is _stateful_, and should be used once per injector.
class InjectorEmitter implements InjectorVisitor {
  static const _package = 'package:angular';
  static const _runtime = '$_package/src/di/injector/injector.dart';
  static const _$override = const Reference('override', 'dart:core');
  static const _$Object = const Reference('Object', 'dart:core');

  static const _$Injector = const Reference('Injector', _runtime);
  static const _$GeneratedInjector =
      const Reference('GeneratedInjector', _runtime);
  static const _$throwIfNotFound = const Reference('throwIfNotFound', _runtime);

  String _className;
  String _factoryName;
  final _fieldCache = <Field>[];
  final _injectSelfBody = <Code>[];

  /// Returns the `class ... { ... }` for this generated injector.
  Class createClass() => new Class((b) => b
    ..name = _className
    ..extend = _$GeneratedInjector
    ..constructors.add(new Constructor((b) => b
      ..name = '_'
      ..optionalParameters.add(new Parameter((b) => b
        ..name = 'parent'
        ..type = _$Injector))
      ..initializers.add(refer('super').call([refer('parent')]).code)))
    ..methods.add(createInjectSelfOptional())
    ..fields.addAll(_fieldCache));

  /// Returns the function that will return a new instance of the class.
  Method createFactory() => new Method((b) => b
    ..name = _factoryName
    ..returns = _$Injector
    ..lambda = true
    ..optionalParameters.add(new Parameter((b) => b
      ..name = 'parent'
      ..type = _$Injector))
    ..body = refer(_className).newInstanceNamed('_', [
      refer('parent'),
    ]).code);

  /// Returns the `Object injectSelfOptional(...)` method for the `class`.
  @visibleForTesting
  Method createInjectSelfOptional() => new Method((b) => b
    ..name = 'injectFromSelfOptional'
    ..returns = _$Object
    ..annotations.add(_$override)
    ..requiredParameters.add(new Parameter((b) => b
      ..name = 'token'
      ..type = _$Object))
    ..optionalParameters.add(new Parameter((b) => b
      ..name = 'orElse'
      ..type = _$Object
      ..defaultTo = _$throwIfNotFound.expression.code))
    ..body = new Block((b) => b
      ..statements.addAll(_injectSelfBody)
      ..statements.add(refer('orElse').returned.statement)));

  /// Returns the fields needed to cache instances in this injector.
  @visibleForTesting
  List<Field> createFields() => _fieldCache;

  @override
  void visitMeta(String className, String factoryName) {
    _className = className;
    _factoryName = factoryName;
  }

  @protected
  static Code _ifIsTokenThen(Expression token, Code then) {
    return new Block.of([
      const Code('if (identical(token, '),
      lazyCode(() => token.code),
      const Code(')) {'),
      then,
      const Code('}'),
    ]);
  }

  @override
  void visitProvideClass(
    int index,
    Expression token,
    Reference type,
    String constructor,
    List<Expression> dependencies,
  ) {
    _fieldCache.add(new Field((b) => b
      ..name = '_field$index'
      ..type = type));
    _injectSelfBody.add(
      _ifIsTokenThen(
        token,
        refer('_field$index')
            .assignNullAware(type.newInstanceNamed(constructor, dependencies))
            .returned
            .statement,
      ),
    );
  }

  @override
  void visitProvideExisting(int index, Expression token, Expression redirect) {
    _injectSelfBody.add(
      _ifIsTokenThen(
        token,
        refer('inject').call([redirect]).returned.statement,
      ),
    );
  }

  @override
  void visitProvideFactory(
    int index,
    Expression token,
    Reference returnType,
    Reference function,
    List<Expression> dependencies,
  ) {
    _fieldCache.add(new Field((b) => b
      ..name = '_field$index'
      ..type = returnType));
    _injectSelfBody.add(
      _ifIsTokenThen(
        token,
        refer('_field$index')
            .assignNullAware(function.call(dependencies))
            .returned
            .statement,
      ),
    );
  }

  @override
  void visitProvideValue(int index, Expression token, Expression value) {
    _injectSelfBody.add(_ifIsTokenThen(token, value.returned.statement));
  }
}
