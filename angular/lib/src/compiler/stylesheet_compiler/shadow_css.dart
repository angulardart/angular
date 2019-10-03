import 'package:angular_compiler/cli.dart';
import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';

/// This is a limited shim for Shadow DOM CSS styling.
///
/// Shimmed features:
///
/// * Shadow Host Selectors
///
///   Allows styling of the shadow host element using :host, :host(), and
///   :host-context() selectors. To shim this feature, these selectors are
///   reformatted and scoped with a host specific class.
///
///     :host               =>  .host
///     :host(div)          =>  div.host
///     :host-context(div)  =>  div.host, div .host
///
/// * Encapsulation
///
///   Styles defined within a shadow tree apply only to its contents. To shim
///   this feature, all selectors except those preceding or containing shadow
///   host selectors are scoped with a host specific content class.
///
///     div               =>  div.content
///     :host(.foo) .bar  =>  .foo.host .bar.content
///
/// * Shadow Piercing Combinators
///
///   The ::ng-deep combinator allows a selector to pierce shadow boundaries and
///   target nodes within a child host's shadow tree. To shim this feature, the
///   combinator is replaced by the descendant combinator, and the following
///   selectors aren't scoped with the host specific content class.
///
///     .x ::ng-deep .y  =>  .x.content .y
///
/// * Polyfill Selectors - DO NOT USE, SUPPORTED FOR LEGACY ONLY
///
///   The 'polyfill-unscoped-rule' selector indicates that the rule set's styles
///   should not be encapsulated.
///
///   For example,
///
///   ```css
///   polyfill-unscoped-rule {
///     content: '.menu > .menu-item';
///     font-size: 12px;
///   }
///   ```
///
///   becomes
///
///   ```css
///   .menu > .menu-item {
///     font-size: 12px;
///   }
///   ```
///
///   The 'polyfill-next-selector' selector allows for application of a separate
///   selector to a rule set only when this shim is applied. This is useful if
///   the native Shadow DOM CSS selector is unsupported by the shim.
///
///   For example,
///
///   ```css
///   polyfill-next-selector { content: ':host .menu'; }
///   ::slotted(.menu) {
///     font-size: 12px;
///   }
///   ```
///
///   becomes
///
///   ```css
///   .host .menu.content {
///     font-size: 12px;
///   }
///   ```
String shimShadowCss(
  String css,
  String contentClass,
  String hostClass, {
  bool useLegacyEncapsulation = false,
}) {
  var errors = <Message>[];
  var styleSheet = parse(css, errors: errors);

  if (errors.isNotEmpty) {
    logWarning('Errors parsing CSS:\n${errors.join('\n')}');
  }

  var shadowTransformer = useLegacyEncapsulation
      ? _LegacyShadowTransformer(contentClass, hostClass)
      : _ShadowTransformer(contentClass, hostClass);
  shadowTransformer.visitTree(styleSheet);
  var printer = CssPrinter();
  printer.visitTree(styleSheet);
  return printer.toString();
}

/// Returns the declaration for property [name] in [group].
///
/// Returns [null] if not found.
Declaration _getDeclaration(DeclarationGroup group, String name) {
  for (var declaration in group.declarations) {
    if (declaration is Declaration && declaration.property == name) {
      return declaration;
    }
  }
  return null;
}

/// Removes all enclosing pairs of single and double quotes from a string.
String _unquote(String value) {
  var start = 0, end = value.length - 1;
  while (start < end &&
      ((value[start] == '"' && value[end] == '"') ||
          (value[start] == "'" && value[end] == "'"))) {
    start++;
    end--;
  }
  return value.substring(start, end + 1);
}

/// Parses a selector from a declaration.
///
/// The declaration expression must be a literal term. Returns [null] if
/// unsuccessful.
SelectorGroup _parseSelectorGroupFrom(Declaration declaration) {
  var expressions = (declaration.expression as Expressions).expressions;
  if (expressions.isEmpty || expressions.first is! LiteralTerm) return null;
  var selectorLiteral = expressions.first as LiteralTerm;
  var selectorText = _unquote(selectorLiteral.text);
  return parseSelectorGroup(selectorText);
}

/// Parses a selector from the declaration for property [propertyName] in
/// [declarationGroup].
///
/// If [remove] is [true], the declaration is removed from [declarationGroup].
SelectorGroup _selectorGroupForProperty(
    DeclarationGroup declarationGroup, String propertyName,
    {bool remove = false}) {
  var declaration = _getDeclaration(declarationGroup, propertyName);
  if (declaration == null) {
    logWarning(
        declarationGroup.span.message("Expected property '$propertyName'"));
    return null;
  }

  if (remove) {
    declarationGroup.declarations.remove(declaration);
  }

  var selectorGroup = _parseSelectorGroupFrom(declaration);
  if (selectorGroup == null) {
    logWarning(declaration.expression.span.message('Not a valid selector'));
    return null;
  }

  return selectorGroup;
}

/// Returns [true] if the selector is ':host'.
bool _isHost(SimpleSelector selector) =>
    selector is PseudoClassSelector && selector.name == 'host';

/// Returns [true] if the selector is ':host()'.
bool _isHostFunction(SimpleSelector selector) =>
    selector is PseudoClassFunctionSelector && selector.name == 'host';

/// Returns [true] if the selector is ':host-context()'.
bool _isHostContextFunction(SimpleSelector selector) =>
    selector is PseudoClassFunctionSelector && selector.name == 'host-context';

/// Returns [true] if [selectorGroup] matches an element named [name].
bool _matchesElement(SelectorGroup selectorGroup, String name) {
  if (selectorGroup.selectors.length != 1) return false;
  var selector = selectorGroup.selectors.first;
  if (selector.simpleSelectorSequences.length != 1) return false;
  var simpleSelector = selector.simpleSelectorSequences.first.simpleSelector;
  return simpleSelector is ElementSelector && simpleSelector.name == name;
}

/// Deep copies a sequence of selectors.
Iterable<SimpleSelectorSequence> _clone(Iterable<SimpleSelectorSequence> it) =>
    it.map((selector) => selector.clone());

SimpleSelectorSequence _createElementSelectorSequence(String name) {
  var identifier = Identifier(name, null);
  var selector = ElementSelector(identifier, null);
  return SimpleSelectorSequence(selector, null);
}

/// Convenience function for terse construction of a class sequence.
SimpleSelectorSequence _createClassSelectorSequence(String name) {
  var identifier = Identifier(name, null);
  var selector = ClassSelector(identifier, null);
  return SimpleSelectorSequence(selector, null);
}

/// Convenience function for terse construction of a pseudo-class sequence.
SimpleSelectorSequence _createPseudoClassSelectorSequence(String name) {
  var identifier = Identifier(name, null);
  var selector = PseudoClassSelector(identifier, null);
  return SimpleSelectorSequence(selector, null);
}

/// Represents a sequence of compound selectors separated by combinators.
///
/// TODO(leonsenft): remove if/when csslib supports Selector Level 4 grammar.
///
/// Grammar:
///   <complex-selector> =
///     <compound-selector> [ <combinator>? <compound-selector> ]*
class _ComplexSelector {
  List<_CompoundSelector> compoundSelectors = [];

  _ComplexSelector();

  _ComplexSelector.from(Selector selector) {
    if (selector.simpleSelectorSequences.isEmpty) return;
    var sequences = selector.simpleSelectorSequences;
    var start = 0;

    for (var i = 1, len = sequences.length; i <= len; i++) {
      if (i == len || !sequences[i].isCombinatorNone) {
        var selectorSequence = sequences.getRange(start, i);
        compoundSelectors.add(_CompoundSelector.from(selectorSequence));
        start = i;
      }
    }
  }

  bool get containsHostContext {
    for (var compoundSelector in compoundSelectors) {
      if (compoundSelector.containsHostContext) return true;
    }
    return false;
  }

  Selector toSelector() {
    var simpleSelectorSequences = <SimpleSelectorSequence>[];
    for (var compoundSelector in compoundSelectors) {
      simpleSelectorSequences.addAll(compoundSelector.toSequences());
    }
    return Selector(simpleSelectorSequences, null);
  }
}

/// Represents a sequence of simple selectors.
///
/// TODO(leonsenft): remove if/when csslib supports Selector Level 4 grammar.
///
/// Grammar:
///   <compound-selector> = <simple-selector>+
///
/// The [combinator] precedes the compound selector when included in a
/// complex selector.
///
/// This class abstracts composing and validating compound selectors. For
/// example, a compound selector may contain at most one type selector and it
/// must be the first selector in the sequence. This behavior is used to detect
/// invalid selectors that are impossible to shim (i.e. :host(div):host(p), a
/// valid but meaningless selector which can't be shimmed).
class _CompoundSelector {
  int combinator;
  List<SimpleSelectorSequence> _sequences = [];

  _CompoundSelector() : combinator = TokenKind.COMBINATOR_NONE;

  _CompoundSelector.from(Iterable<SimpleSelectorSequence> sequences) {
    combinator = sequences.isEmpty
        ? TokenKind.COMBINATOR_NONE
        : sequences.first.combinator;
    addAll(sequences);
  }

  bool get containsHost {
    for (var sequence in _sequences) {
      if (_isHost(sequence.simpleSelector)) return true;
    }
    return false;
  }

  bool get containsHostContext {
    for (var sequence in _sequences) {
      if (_isHostContextFunction(sequence.simpleSelector)) return true;
    }
    return false;
  }

  /// Replaces this with an empty type selector if it's `::ng-deep`.
  ///
  /// `::ng-deep` is replaced with an empty tag, rather than removed, to
  /// preserve adjacent combinators.
  ///
  /// Returns true if a replacement occurs.
  bool removeIfNgDeep() {
    if (_sequences.isEmpty) return false;
    final selector = _sequences.first.simpleSelector;
    if (selector is PseudoElementSelector && selector.name == 'ng-deep') {
      _sequences = [
        _createElementSelectorSequence('')..combinator = combinator
      ];
      return true;
    }
    return false;
  }

  /// Determines the ordering of two selectors in a valid compound selector.
  ///
  /// Returns
  /// * a negative integer if [a] should precede [b],
  /// * zero if the order of [a] and [b] is irrelevant, and
  /// * a positive integer if [b] should precede [a].
  int _compare(SimpleSelectorSequence a, SimpleSelectorSequence b) {
    var x = a.simpleSelector;
    var y = b.simpleSelector;

    if ((x is ElementSelector && y is ElementSelector) ||
        (x is NamespaceSelector && y is NamespaceSelector)) {
      logWarning('Compound selector contains multiple type selectors:\n'
          '${x.span.message('')}\n'
          '${y.span.message('')}');
      return 0;
    } else if (x is PseudoElementSelector && y is PseudoElementSelector) {
      logWarning(
          'Compound selector contains multiple pseudo element selectors:\n'
          '${x.span.message('')}\n'
          '${y.span.message('')}');
      return 0;
    } else if (x is PseudoElementSelector ||
        y is ElementSelector ||
        y is NamespaceSelector) {
      return 1;
    } else if (y is PseudoElementSelector ||
        x is ElementSelector ||
        x is NamespaceSelector) {
      return -1;
    }

    return 0;
  }

  void append(SimpleSelectorSequence sequence) => _sequences.add(sequence);

  void add(SimpleSelectorSequence sequence) {
    var i = 0;
    for (var len = _sequences.length; i < len; i++) {
      if (_compare(sequence, _sequences[i]) < 0) break;
    }
    _sequences.insert(i, sequence);
  }

  void addAll(Iterable<SimpleSelectorSequence> sequences) {
    var newSequences = <SimpleSelectorSequence>[];
    var sequencesIt = _sequences.iterator;
    var additionsIt = sequences.iterator;
    var sequencesHasNext = sequencesIt.moveNext();
    var additionsHasNext = additionsIt.moveNext();

    // Merge sequences while both have selectors.
    while (sequencesHasNext && additionsHasNext) {
      if (_compare(additionsIt.current, sequencesIt.current) < 0) {
        newSequences.add(additionsIt.current);
        additionsHasNext = additionsIt.moveNext();
      } else {
        newSequences.add(sequencesIt.current);
        sequencesHasNext = sequencesIt.moveNext();
      }
    }

    // Append remaining selectors from original sequence.
    while (sequencesHasNext) {
      newSequences.add(sequencesIt.current);
      sequencesHasNext = sequencesIt.moveNext();
    }

    // Append remaining selectors from additions.
    while (additionsHasNext) {
      newSequences.add(additionsIt.current);
      additionsHasNext = additionsIt.moveNext();
    }

    _sequences = newSequences;
  }

  _CompoundSelector clone() {
    var compoundSelector = _CompoundSelector()..combinator = combinator;
    for (var sequence in _sequences) {
      compoundSelector._sequences.add(sequence.clone());
    }
    return compoundSelector;
  }

  Iterable<SimpleSelectorSequence> toSequences() {
    if (_sequences.isNotEmpty) {
      for (var sequence in _sequences) {
        sequence.combinator = TokenKind.COMBINATOR_NONE;
      }
      _sequences.first.combinator = combinator;
    }
    return _sequences;
  }
}

class _Indices {
  /// Index of first compound selector following a shadow piercing combinator.
  int deepIndex;

  /// Index of last compound selector containing a shadow host selector.
  int hostIndex;

  _Indices(this.deepIndex, this.hostIndex);
}

/// Shims selectors to emulate Shadow DOM CSS style encapsulation.
class _ShadowTransformer extends Visitor {
  final String _contentClass;
  final String _hostClass;

  _ShadowTransformer(this._contentClass, this._hostClass);

  @override
  void visitTree(StyleSheet tree) {
    tree.visit(this);
  }

  /// Shimming :host-context() requires two selectors. One which matches the
  /// selector argument to the shadow host, and one which matches it against an
  /// ancestor. This method creates the latter, where the shadow host is a
  /// descendant. The former is handled by shimming the original selector
  /// itself.
  ///
  /// Example:
  ///   :host-context(.x) > .y  =>  .x :host > .y
  _ComplexSelector _createDescendantHostSelectorFor(_ComplexSelector selector) {
    var newSelector = _ComplexSelector();

    for (var compoundSelector in selector.compoundSelectors) {
      if (compoundSelector.containsHostContext) {
        var ancestor = _CompoundSelector()
          ..combinator = compoundSelector.combinator;
        var descendant = _CompoundSelector()
          ..combinator = TokenKind.COMBINATOR_DESCENDANT;
        var sequences = _clone(compoundSelector.toSequences());

        for (var sequence in sequences) {
          var simpleSelector = sequence.simpleSelector;

          if (_isHostContextFunction(simpleSelector)) {
            var hostContext = simpleSelector as PseudoClassFunctionSelector;
            ancestor.addAll(hostContext.selector.simpleSelectorSequences);
          } else {
            descendant.append(sequence);
          }
        }

        descendant.add(_createPseudoClassSelectorSequence('host'));
        newSelector.compoundSelectors.add(ancestor);
        newSelector.compoundSelectors.add(descendant);
      } else {
        newSelector.compoundSelectors.add(compoundSelector.clone());
      }
    }

    return newSelector;
  }

  /// Replaces shadow piercing combinators with descendant combinators and
  /// records [indices].
  void shimDeepCombinators(_ComplexSelector selector, _Indices indices) {
    for (var i = selector.compoundSelectors.length - 1; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];

      // Shim '::ng-deep'
      if (compoundSelector.removeIfNgDeep()) indices.deepIndex = i;
    }
  }

  /// Shims Shadow DOM CSS features to emulate style encapsulation.
  ///
  /// Example:
  ///   :host(.x) > .y ::ng-deep .z  =>  .x.host > .y.content .z
  void shimSelectors(_ComplexSelector selector) {
    var indices = _Indices(selector.compoundSelectors.length, -1);
    shimDeepCombinators(selector, indices);

    // Scope all selectors between the last host selector and the first shadow
    // piercing combinator. We intentionally don't scope selectors BEFORE host
    // selectors for two reasons. Firstly, the :host-context() shim depends on
    // this behavior. Secondly, the shadow host could never possibly be a
    // descendant or sibling or its own content.
    for (var i = indices.deepIndex - 1; i > indices.hostIndex; i--) {
      var compoundSelector = selector.compoundSelectors[i];
      if (compoundSelector.containsHost ||
          compoundSelector.containsHostContext) {
        indices.hostIndex = i;
      } else {
        compoundSelector.add(_createClassSelectorSequence(_contentClass));
      }
    }

    // Shim all host selectors.
    for (var i = indices.hostIndex; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];

      for (var j = 0; j < compoundSelector._sequences.length; j++) {
        var selector = compoundSelector._sequences[j].simpleSelector;
        if (_isHostFunction(selector) || _isHostContextFunction(selector)) {
          // Replace :host() or :host-context() with host class.
          compoundSelector._sequences[j] =
              _createClassSelectorSequence(_hostClass);

          // Add :host() or :host-context() argument to constituent selector.
          var hostFn = selector as PseudoClassFunctionSelector;
          var hostArg = _clone(hostFn.selector.simpleSelectorSequences);
          compoundSelector.addAll(hostArg);
        } else if (_isHost(selector)) {
          // Replace :host with host class.
          compoundSelector._sequences[j] =
              _createClassSelectorSequence(_hostClass);
        }
      }
    }
  }

  @override
  void visitSelectorGroup(SelectorGroup node) {
    var complexSelectors = <_ComplexSelector>[];
    for (var selector in node.selectors) {
      // Convert [Selector] to [ComplexSelector] to facilitate shimming
      // transformations.
      var complexSelector = _ComplexSelector.from(selector);
      complexSelectors.add(complexSelector);

      if (complexSelector.containsHostContext) {
        // Add a new selector which matches the host as a descendant of the
        // selector argument to :host-context().
        complexSelectors.add(_createDescendantHostSelectorFor(complexSelector));
      }
    }

    // Replace original selectors with shimmed selectors.
    var nodeSelectors = node.selectors;
    nodeSelectors.clear();
    for (var complexSelector in complexSelectors) {
      shimSelectors(complexSelector);
      nodeSelectors.add(complexSelector.toSelector());
    }
  }
}

class _LegacyShadowTransformer extends _ShadowTransformer {
  _LegacyShadowTransformer(String contentClass, String hostClass)
      : super(contentClass, hostClass);

  final _unscopedSelectorGroups = <SelectorGroup>{};

  void _shimPolyfillNextSelector(List<TreeNode> list) {
    SelectorGroup nextSelectorGroup;

    // Apply 'polyfill-next-selector' transformations.
    for (var node in list) {
      if (node is RuleSet) {
        if (nextSelectorGroup != null) {
          // Override selector.
          node.selectorGroup.selectors
            ..clear()
            ..addAll(nextSelectorGroup.selectors);
          // Consume selector so subsequent selectors aren't overwritten.
          nextSelectorGroup = null;
        } else if (_matchesElement(
            node.selectorGroup, 'polyfill-next-selector')) {
          nextSelectorGroup =
              _selectorGroupForProperty(node.declarationGroup, 'content');
        }
      }
    }

    // Remove 'polyfill-next-selector' rule sets.
    list.removeWhere((node) => node is RuleSet
        ? _matchesElement(node.selectorGroup, 'polyfill-next-selector')
        : false);
  }

  void _shimPolyfillUnscopedRule(RuleSet ruleSet) {
    if (_matchesElement(ruleSet.selectorGroup, 'polyfill-unscoped-rule')) {
      var contentSelectorGroup = _selectorGroupForProperty(
          ruleSet.declarationGroup, 'content',
          remove: true);
      if (contentSelectorGroup != null) {
        ruleSet.selectorGroup.selectors
          ..clear()
          ..addAll(contentSelectorGroup.selectors);
      }
      _unscopedSelectorGroups.add(ruleSet.selectorGroup);
    }
  }

  @override
  void shimDeepCombinators(_ComplexSelector selector, _Indices indices) {
    for (var i = selector.compoundSelectors.length - 1; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];
      if (compoundSelector.containsHost ||
          compoundSelector.containsHostContext) {
        // Don't scope selectors following a shadow host selector.
        indices.deepIndex = i;
        indices.hostIndex = i;
      } else if (compoundSelector.removeIfNgDeep()) {
        indices.deepIndex = i;
      }
    }
  }

  @override
  void shimSelectors(_ComplexSelector selector) {
    // Remove all ::content and ::shadow selectors. This does not correctly
    // emulate the behavior of these selectors, however, the shim never has
    // and we're just maintaining backwards compatibility until these are
    // removed entirely.
    selector.compoundSelectors.removeWhere((compoundSelector) {
      compoundSelector._sequences.removeWhere((sequence) {
        var selector = sequence.simpleSelector;
        return selector is PseudoElementSelector &&
            (selector.name == 'content' || selector.name == 'shadow');
      });
      return compoundSelector._sequences.isEmpty;
    });

    super.shimSelectors(selector);
  }

  @override
  void visitTree(StyleSheet tree) {
    tree.visit(this);
    _unscopedSelectorGroups.clear();
  }

  @override
  void visitDeclarationGroup(DeclarationGroup node) {
    _shimPolyfillNextSelector(node.declarations);
    super.visitDeclarationGroup(node);
  }

  @override
  void visitMediaDirective(MediaDirective node) {
    _shimPolyfillNextSelector(node.rules);
    super.visitMediaDirective(node);
  }

  @override
  void visitRuleSet(RuleSet node) {
    _shimPolyfillUnscopedRule(node);
    super.visitRuleSet(node);
  }

  @override
  void visitSelectorGroup(SelectorGroup node) {
    if (!_unscopedSelectorGroups.contains(node)) {
      super.visitSelectorGroup(node);
    }
  }

  @override
  void visitStyleSheet(StyleSheet node) {
    _shimPolyfillNextSelector(node.topLevels);
    super.visitStyleSheet(node);
  }
}
