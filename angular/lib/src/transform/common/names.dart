const BOOTSTRAP_NAME = 'bootstrap';
const BOOTSTRAP_STATIC_NAME = 'bootstrapStatic';
const SETUP_METHOD_NAME = 'initReflector';
const REFLECTOR_VAR_NAME = 'reflector';
const TRANSFORM_DYNAMIC_MODE = 'transform_dynamic';
const CSS_EXTENSION = '.css';
const DEFERRED_EXTENSION = '.dart.deferredCount';
const SHIMMED_STYLESHEET_EXTENSION = '.css.shim.dart';
const NON_SHIMMED_STYLESHEET_EXTENSION = '.css.dart';
const REFLECTION_CAPABILITIES_NAME = 'ReflectionCapabilities';
const REFLECTOR_IMPORT = 'package:angular/src/core/reflection/reflection.dart';
const TEMPLATE_EXTENSION = '.template.dart';

/// Note that due to the implementation of `_toExtension`, ordering is
/// important. For example, putting '.dart' first in this list will cause
/// incorrect behavior because it will (incompletely) match '.template.dart'
/// files.
const ALL_EXTENSIONS = const [
  DEFERRED_EXTENSION,
  TEMPLATE_EXTENSION,
  '.ng_placeholder',
  '.dart'
];

/// Whether `uri` was created by a transform phase.
///
/// This may return false positives for problematic inputs.
/// This just tests file extensions known to be created by the transformer, so
/// any files named like transformer outputs will be reported as generated.
bool isGenerated(String uri) {
  return const [
    DEFERRED_EXTENSION,
    NON_SHIMMED_STYLESHEET_EXTENSION,
    SHIMMED_STYLESHEET_EXTENSION,
    TEMPLATE_EXTENSION,
    '.ng_placeholder',
  ].any((ext) => uri.endsWith(ext));
}

/// Returns `uri` with its extension updated to [DEFERRED_EXTENSION].
String toDeferredExtension(String uri) =>
    _toExtension(uri, ALL_EXTENSIONS, DEFERRED_EXTENSION);

/// Returns `uri` with its extension updated to [TEMPLATES_EXTENSION].
String toTemplateExtension(String uri) =>
    _toExtension(uri, ALL_EXTENSIONS, TEMPLATE_EXTENSION);

/// Returns `uri` with its extension updated to `toExtension` if its
/// extension is currently in `fromExtension`.
String _toExtension(
    String uri, Iterable<String> fromExtensions, String toExtension) {
  if (uri == null) return null;
  if (uri.endsWith(toExtension)) return uri;
  for (var extension in fromExtensions) {
    if (uri.endsWith(extension)) {
      return '${uri.substring(0, uri.length-extension.length)}'
          '$toExtension';
    }
  }
  throw new ArgumentError.value(
      uri,
      'uri',
      'Provided value ends with an unexpected extension. '
      'Expected extension(s): [${fromExtensions.join(', ')}].');
}
