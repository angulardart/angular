import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';

/// An abstraction around determining information about library dependencies.
class MetadataLibrary {
  // A to-be-created .template.dart file (needs linking in a future phase).
  static const _unlinkedTemplateExtension = '.template.dart-unlinked';

  // A linked and generated companion file to an AngularDart library.
  static const _templateExtension = '.template.dart';

  // Returns whether the top-level function `initReflector` exists.
  static bool _hasInitReflector(LibraryElement element) => element.units
      .any((unit) => unit is FunctionElement && unit.name == 'initReflector');

  const MetadataLibrary();

  /// Returns `true` if an `import` or `export` [directive] must be linked.
  ///
  /// _Linking_ is the action of generating code that imports a file's
  /// `.template.dart` file, and calls the top-level function `initReflector`.
  ///
  /// For example, if you have the following input source file:
  /// ```
  /// import 'package:a/a.dart';
  /// ```
  ///
  /// We generate something like:
  /// ```
  /// import 'package:a/a.dart';
  /// //%%LINK:IMPORTS
  ///
  /// void initReflector() {
  ///   //%%LINK:INIT_REFLECTOR
  /// }
  /// ```
  ///
  /// In a future phase, any `import` or `export` that passes this function
  /// is linked by adding a new import and a call to `initReflector`:
  /// ```
  /// import 'package:a/a.dart';
  /// import 'package:a/a.template.dart' as link_1;
  ///
  /// void initReflector() {
  ///   link_1.initReflector();
  /// }
  /// ```
  bool requiresLinkToLibrary(
    Resolver resolver,
    UriReferencedElement directive,
  ) {
    final assetId = new AssetId.parse(directive.uri);
    final assetUnlinked = assetId.changeExtension(_unlinkedTemplateExtension);
    if (resolver.isLibrary(assetUnlinked)) {
      return _hasInitReflector(resolver.getLibrary(assetUnlinked));
    }
    final assetTemplate = assetId.changeExtension(_templateExtension);
    if (resolver.isLibrary(assetTemplate)) {
      return _hasInitReflector(resolver.getLibrary(assetTemplate));
    }
    return false;
  }
}
