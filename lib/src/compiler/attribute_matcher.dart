/// Matches HTML attribute values.
///
/// Note that matching the attribute name is left to the caller. This improves
/// the efficiency of matching an attribute against a collection of
/// [AttributeMatcher]s that share a name.
///
/// https://www.w3.org/TR/selectors4/#attribute-selectors
abstract class AttributeMatcher {
  final String name;
  final String value;

  const AttributeMatcher(this.name, this.value);

  bool matches(String value);
}

/// Matches a value that is exactly [value].
///
/// https://www.w3.org/TR/selectors4/#attribute-representation
class ExactAttributeMatcher extends AttributeMatcher {
  ExactAttributeMatcher(String name, String value) : super(name, value);

  @override
  bool matches(String value) => value == this.value;

  @override
  String toString() => '[$name="$value"]';
}

/// Matches a value that is exactly [value] or prefixed by [value]-.
///
/// https://www.w3.org/TR/selectors4/#attribute-representation
class HyphenAttributeMatcher extends AttributeMatcher {
  final String _prefix;

  HyphenAttributeMatcher(String name, String value)
      : _prefix = '$value-',
        super(name, value);

  @override
  bool matches(String value) =>
      value == this.value || value.startsWith(_prefix);

  @override
  String toString() => '[$name|="$value"]';
}

/// Matches a whitespace-delimited list of words containing [value].
///
/// https://www.w3.org/TR/selectors4/#attribute-representation
class ListAttributeMatcher extends AttributeMatcher {
  static final _whitespaceRe = new RegExp(r'\s+');

  ListAttributeMatcher(String name, String item) : super(name, item);

  @override
  bool matches(String value) => value.split(_whitespaceRe).contains(this.value);

  @override
  String toString() => '[$name~="$value"]';
}

/// Matches a value that begins with the prefix [value].
///
/// https://www.w3.org/TR/selectors4/#attribute-substrings
class PrefixAttributeMatcher extends AttributeMatcher {
  PrefixAttributeMatcher(String name, String prefix) : super(name, prefix);

  @override
  bool matches(String value) => value.startsWith(this.value);

  @override
  String toString() => '[$name^="$value"]';
}

/// Matches any value.
///
/// https://www.w3.org/TR/selectors4/#attribute-representation
class SetAttributeMatcher extends AttributeMatcher {
  SetAttributeMatcher(String name) : super(name, null);

  @override
  bool matches(String value) => true;

  @override
  String toString() => '[$name]';
}

/// Matches a value that contains the substring [value].
///
/// https://www.w3.org/TR/selectors4/#attribute-substrings
class SubstringAttributeMatcher extends AttributeMatcher {
  SubstringAttributeMatcher(String name, String substring)
      : super(name, substring);

  @override
  bool matches(String value) => value.contains(this.value);

  @override
  String toString() => '[$name*="$value"]';
}

/// Matches a value that ends with the suffix [value].
///
/// https://www.w3.org/TR/selectors4/#attribute-substrings
class SuffixAttributeMatcher extends AttributeMatcher {
  SuffixAttributeMatcher(String name, String suffix) : super(name, suffix);

  @override
  bool matches(String value) => value.endsWith(this.value);

  @override
  String toString() => '[$name\$="$value"]';
}
