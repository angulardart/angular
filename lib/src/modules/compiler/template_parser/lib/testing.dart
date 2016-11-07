import 'template_parser.dart';

/// Returns the visible error message when parsing [template].
///
/// Like [getParseErrors] but expects only a single error.
String getParseError(String template, {NgTemplateParser parser}) {
  return getParseErrors(template, parser: parser).single;
}

/// Returns a [List<String>] of caught errors when parsing [template].
///
/// May specify a [parser] implementation, or use a default.
List<String> getParseErrors(String template, {NgTemplateParser parser}) {
  final errors = <Error> [];
  (parser ?? const NgTemplateParser()).parse(template, onError: errors.add);
  return errors.map((e) => e.toString()).toList();
}
