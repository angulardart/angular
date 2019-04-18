/// A constraint system for suggesting full HTML tags from a [Selector].
///
/// Where possible it is good to be able to suggest a fully completed html tag
/// to match a selector. This has a few challenges: the selector may match
/// multiple things, it may not include any tag name to go off of at all. It may
/// lend itself to infinite suggestions (such as matching a regex), and parts
/// of its selector may cancel other parts out leading to invalid suggestions
/// (such as [prop=this][prop=thistoo]), especially in the presence of heavy
/// booleans.
///
/// This doesn't track :not, so it may still suggest invalid things, but in
/// general the goal of this class is that its an empty shell which tracks
/// conflicting information.
///
/// Each selector takes in the current round of suggestions in
/// [refineTagSuggestions], and may return more suggestions than it got
/// originally (as in OR). At the end, all valid selectors can be checked for
/// validity.
///
/// Selector.suggestTags() handles creating a seed HtmlTagForSelector and
/// stripping invalid suggestions at the end, potentially resulting in none.
class HtmlTagForSelector {
  String _name;
  final _attributes = <String, String>{};
  bool _isValid = true;
  final _classes = <String>{};

  /// A tag is invalid if its constraints are unsatisfiable.
  bool get isValid => _name != null && _isValid && _classAttrValid;

  /// The required tag name of this tag.
  String get name => _name;

  /// Constrain the name of this tag.
  ///
  /// If the name is already constrained, and the new name does not match the
  /// old, this will produce an invalid tag.
  set name(String name) {
    if (_name != null && _name != name) {
      _isValid = false;
    } else {
      _name = name;
    }
  }

  bool get _classAttrValid => _classes.isEmpty || _attributes["class"] == null
      ? true
      : _classes.length == 1 && _classes.first == _attributes["class"];

  /// Constrain the classes of this tag by adding a required class.
  void addClass(String classname) {
    _classes.add(classname);
  }

  HtmlTagForSelector clone() => HtmlTagForSelector()
    ..name = _name
    .._attributes.addAll(_attributes)
    .._isValid = _isValid
    .._classes.addAll(_classes);

  /// Constrain the attribute [name] to exist, potentially with [value].
  ///
  /// If the attribute is already expected to exist with a different non-null
  /// [value], then this will produce an invalid tag.
  void setAttribute(String name, {String value}) {
    // New constraint; always add.
    if (!_attributes.containsKey(name)) {
      _attributes[name] = value;
      return;
    }

    // Valueless constraint, we know there's no contradiction. Exit.
    if (value == null) {
      return;
    }

    // Previous constrained values must match the new value
    if (_attributes[name] != null && _attributes[name] != value) {
      _isValid = false;
    } else {
      // unconstrained values get a value constraint
      _attributes[name] = value;
    }
  }

  @override
  String toString() {
    final keepClassAttr = _classes.isEmpty;

    final attrStrs = <String>[];
    _attributes.forEach((k, v) {
      // in the case of [class].myclass don't create multiple class attrs
      if (k != "class" || keepClassAttr) {
        attrStrs.add(v == null ? k : '$k="$v"');
      }
    });

    if (_classes.isNotEmpty) {
      final classesList = (_classes.toList()..sort()).join(' ');
      attrStrs.add('class="$classesList"');
    }

    attrStrs.sort();

    return (['<$_name']..addAll(attrStrs)).join(' ');
  }
}
