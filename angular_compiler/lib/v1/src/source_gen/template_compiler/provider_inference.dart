import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/v2/context.dart';

/// Returns the [CompileTypeMetadata] appropriate for `T` in `Provider<T>`.
DartType? inferProviderType(DartObject provider, DartObject token) {
  // Complexity of code is two-fold:
  //
  // 1. The analyzer has subtle top-level inference bugs. Sometimes the <T>
  //    may be reported as dynamic or Object, when otherwise it would be
  //    (correctly) inferred as a the T from an existing OpaqueToken<T>.
  //    https://github.com/dart-lang/sdk/issues/32290
  //
  // 2. In the case of MultiToken<T>, the token type strictly speaking is
  //    List<T>, but we want to encode it as a <T> with the "multi" flag
  //    set. This means that providers that use multi tokens need a special
  //    case.
  //
  // Check for MultiToken<T>.
  final tokenType = token.type;
  if (tokenType != null && $MultiToken.isAssignableFromType(tokenType)) {
    if (tokenType is InterfaceType && $MultiToken.isExactlyType(tokenType)) {
      return tokenType.typeArguments.first;
    }
    // Check for a _custom_ MultiToken<T>
    final tokenTypeClass = tokenType.element;
    if (tokenTypeClass is ClassElement) {
      var supertype = tokenTypeClass.supertype!;
      if (!$MultiToken.isExactlyType(supertype)) {
        // When we start using angular_compiler to resolve all of the time
        // remove this message, since we already validate there.
        throw BuildError.forElement(
            tokenType.element!,
            'A sub-type of OpaqueToken must directly extend OpaqueToken or '
            'MultiToken, and cannot extend another class that in turn extends '
            'OpaqueToken or MultiToken.\n\n'
            'We may loosten these restrictions in the future. See: '
            'https://github.com/angulardart/angular/issues/899');
      }
      return supertype.typeArguments.first;
    }
  }
  // Lookup Inferred Type (i.e. the <T> recorded for Provider<T>).
  var providerType = provider.type;
  if (providerType is InterfaceType) {
    final providerOfTArgs = providerType.typeArguments;
    if (providerOfTArgs.isNotEmpty) {
      final genericType = providerOfTArgs.first;
      // If type inference fails it might resolve to dynamic or Object.
      if (!genericType.isDynamic && !genericType.isDartCoreObject) {
        return genericType;
      }
    }
  }
  // Fallback and try to extract from OpaqueToken<T>.
  if (tokenType is InterfaceType &&
      $OpaqueToken.isAssignableFromType(tokenType) &&
      // Only apply "auto inference" to "new-type" Providers like
      // Value, Class, Existing, FactoryProvider.
      !$Provider.isExactlyType(provider.type!) &&
      tokenType.typeArguments.isNotEmpty) {
    final opaqueTokenOfT = tokenType.typeArguments.first;
    if (!opaqueTokenOfT.isDynamic) {
      return opaqueTokenOfT;
    }
  }

  // We failed to find any type we can use. This will mean "dynamic" elsewhere.
  return null;
}
