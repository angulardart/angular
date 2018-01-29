const CSS_EXTENSION = '.css';
const SHIMMED_STYLESHEET_EXTENSION = '.css.shim.dart';
const NON_SHIMMED_STYLESHEET_EXTENSION = '.css.dart';
const TEMPLATE_EXTENSION = '.template.dart';
const _DEFERRED_EXTENSION = '.dart.deferredCount';

/// Note that due to the implementation of `_toExtension`, ordering is
/// important. For example, putting '.dart' first in this list will cause
/// incorrect behavior because it will (incompletely) match '.template.dart'
/// files.
const ALL_EXTENSIONS = const [
  _DEFERRED_EXTENSION,
  TEMPLATE_EXTENSION,
  '.ng_placeholder',
  '.dart'
];

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
