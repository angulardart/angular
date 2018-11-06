import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

/// Returns the generic type parameters, mapped by class name, of [directives].
///
/// Generic type parameters are returned exactly as written in source. If a
/// directive isn't generic, its type parameters are represented as the empty
/// string.
///
/// For example, if [directives] contains class elements for `Foo` and `Bar`
/// which are declared as
///
/// ```
/// class Foo {}
/// class Bar<T, R extends prefix.Bound> { ... }
/// ```
///
/// this returns
///
/// ```
/// {
///   'Foo': '',
///   'Bar': '<T, R extends prefix.Bound>',
/// }
/// ```
Future<Map<String, String>> collectTypeParameters(
    Iterable<ClassElement> directives, BuildStep buildStep) async {
  final typeParameters = <String, String>{};
  final unitsToParse = Set<String>();
  for (final directive in directives) {
    typeParameters[directive.name] = '';
    if (directive.typeParameters != null) {
      unitsToParse.add(directive.source.fullName);
    }
  }
  // Avoid parsing source if there are no directives with generic type
  // parameters to collect.
  if (unitsToParse.isNotEmpty) {
    await Future.wait(unitsToParse.map((unit) =>
        _collectTypeParametersFromUnit(unit, buildStep, typeParameters)));
  }
  return typeParameters;
}

/// Records the generic type parameters of classes in a compilation unit.
///
/// [unitName] identifies the source of the compilation unit to parse.
///
/// [typeParameters] must contain an entry, keyed by class name, for each class
/// whose type parameters should be collected. Any collected type parameters are
/// recorded in [typeParameters], overwriting the original value.
Future<void> _collectTypeParametersFromUnit(
  String unitName,
  BuildStep buildStep,
  Map<String, String> typeParameters,
) async {
  // Parse unresolved compilation unit from source. This is cheaper than
  // accessing the resolved compilation unit through the element model.
  final id = AssetId.parse(unitName);
  final source = await buildStep.readAsString(id);
  final unit = parseCompilationUnit(source,
      name: '${id.uri}', parseFunctionBodies: false);
  // Collect generic type parameters for directives.
  for (final declaration in unit.declarations) {
    if (declaration is ClassDeclaration &&
        declaration.typeParameters != null &&
        typeParameters.containsKey(declaration.name.name)) {
      typeParameters[declaration.name.name] = source.substring(
        declaration.typeParameters.offset,
        declaration.typeParameters.end,
      );
    }
  }
}
