import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';
import 'package:quiver/iterables.dart' show merge;
import "package:logging/logging.dart";

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
///   The >>> combinator allows a selector to pierce shadow boundaries and
///   target nodes within a child host's shadow tree. To shim this feature, the
///   combinator is replaced by the descendant combinator, and the following
///   selectors aren't scoped with the host specific content class.
///
///     .x >>> .y  =>  .x.content .y
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
String shimShadowCss(String css, String contentClass, String hostClass) {
  // Hack to replace all sequential >>> (and alias /deep/) combinators with a
  // single >>> combinator. These sequences occur commonly in CSS generated from
  // SASS like the example shown:
  //
  // SASS:
  //  @mixin a() {
  //    /deep/ .x {
  //      color: red;
  //    }
  //  }
  //
  //  .y /deep/ {
  //    @include a();
  //  }
  css = css.replaceAll(_consecutiveShadowPiercingCombinatorsRe, '>>> ');

  var errors = <Message>[];
  var styleSheet = parse(css, errors: errors);

  if (errors.isNotEmpty) {
    _logger.warning('Errors parsing CSS:\n${errors.join('\n')}');
  }

  var shadowTransformer = new ShadowTransformer(contentClass, hostClass);
  shadowTransformer.visitTree(styleSheet);
  var printer = new CssPrinter();
  printer.visitTree(styleSheet);
  return printer.toString();
}

final Logger _logger = new Logger('angulardart.shadowcss');

// Matches two or more consecutive '>>>' and '/deep/' combinators.
final RegExp _consecutiveShadowPiercingCombinatorsRe =
    new RegExp(r'(?:(?:/deep/|>>>)\s*){2,}');

/// Returns the declaration for property [name] in [group].
///
/// Returns [null] if not found.
Declaration getDeclaration(DeclarationGroup group, String name) {
  for (var declaration in group.declarations) {
    if (declaration is Declaration && declaration.property == name) {
      return declaration;
    }
  }
  return null;
}

/// Removes all enclosing pairs of single and double quotes from a string.
String unquote(String value) {
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
SelectorGroup parseSelectorGroupFrom(Declaration declaration) {
  var expressions = (declaration.expression as Expressions).expressions;
  if (expressions.isEmpty || expressions.first is! LiteralTerm) return null;
  var selectorLiteral = expressions.first as LiteralTerm;
  var selectorText = unquote(selectorLiteral.text);
  return parseSelectorGroup(selectorText);
}

/// Parses a selector from the declaration for property [propertyName] in
/// [declarationGroup].
///
/// If [remove] is [true], the declaration is removed from [declarationGroup].
SelectorGroup selectorGroupForProperty(
    DeclarationGroup declarationGroup, String propertyName,
    {bool remove: false}) {
  var declaration = getDeclaration(declarationGroup, propertyName);
  if (declaration == null) {
    _logger.warning(
        declarationGroup.span.message("Expected property '$propertyName'"));
    return null;
  }

  if (remove) declarationGroup.declarations.remove(declaration);

  var selectorGroup = parseSelectorGroupFrom(declaration);
  if (selectorGroup == null) {
    _logger
        .warning(declaration.expression.span.message('Not a valid selector'));
    return null;
  }

  return selectorGroup;
}

/// Returns [true] if the selector is ':host'.
bool isHost(SimpleSelector selector) =>
    selector is PseudoClassSelector && selector.name == 'host';

/// Returns [true] if the selector is ':host()'.
bool isHostFunction(SimpleSelector selector) =>
    selector is PseudoClassFunctionSelector && selector.name == 'host';

/// Returns [true] if the selector is ':host-context()'.
bool isHostContextFunction(SimpleSelector selector) =>
    selector is PseudoClassFunctionSelector && selector.name == 'host-context';

/// Returns [true] if [selectorGroup] matches an element named [name].
bool matchesElement(SelectorGroup selectorGroup, String name) {
  if (selectorGroup.selectors.length != 1) return false;
  var selector = selectorGroup.selectors.first;
  if (selector.simpleSelectorSequences.length != 1) return false;
  var simpleSelector = selector.simpleSelectorSequences.first.simpleSelector;
  return simpleSelector is ElementSelector && simpleSelector.name == name;
}

/// Deep copies a sequence of selectors.
Iterable<SimpleSelectorSequence> clone(Iterable<SimpleSelectorSequence> it) =>
    it.map((selector) => selector.clone());

/// Convenience function for terse construction of a class sequence.
SimpleSelectorSequence createClassSelectorSequence(String name) {
  var identifier = new Identifier(name, null);
  var selector = new ClassSelector(identifier, null);
  return new SimpleSelectorSequence(selector, null);
}

/// Convenience function for terse construction of a pseudo-class sequence.
SimpleSelectorSequence createPseudoClassSelectorSequence(String name) {
  var identifier = new Identifier(name, null);
  var selector = new PseudoClassSelector(identifier, null);
  return new SimpleSelectorSequence(selector, null);
}

/// Represents a sequence of compound selectors separated by combinators.
///
/// TODO(leonsenft): remove if/when csslib supports Selector Level 4 grammar.
///
/// Grammar:
///   <complex-selector> =
///     <compound-selector> [ <combinator>? <compound-selector> ]*
class ComplexSelector {
  List<CompoundSelector> compoundSelectors = [];

  ComplexSelector();

  ComplexSelector.from(Selector selector) {
    if (selector.simpleSelectorSequences.isEmpty) return;
    var sequences = selector.simpleSelectorSequences;
    var start = 0;

    for (var i = 1, len = sequences.length; i <= len; i++) {
      if (i == len || !sequences[i].isCombinatorNone) {
        var selectorSequence = sequences.getRange(start, i);
        compoundSelectors.add(new CompoundSelector.from(selectorSequence));
        start = i;
      }
    }
  }

  bool get containsHostContext {
    return compoundSelectors.any((selector) => selector.containsHostContext);
  }

  Selector toSelector() {
    var simpleSelectorSequences = compoundSelectors
        .map((compoundSelector) => compoundSelector.toSequences())
        .expand((sequence) => sequence)
        .toList();
    return new Selector(simpleSelectorSequences, null);
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
class CompoundSelector {
  int combinator;
  List<SimpleSelectorSequence> _sequences = [];

  CompoundSelector() : combinator = TokenKind.COMBINATOR_NONE;

  CompoundSelector.from(Iterable<SimpleSelectorSequence> sequences) {
    combinator = sequences.isEmpty
        ? TokenKind.COMBINATOR_NONE
        : sequences.first.combinator;
    addAll(sequences);
  }

  bool get containsHost =>
      _sequences.any((sequence) => isHost(sequence.simpleSelector));

  bool get containsHostContext => _sequences
      .any((sequence) => isHostContextFunction(sequence.simpleSelector));

  /// Determines the ordering of two selectors in a valid compound selector.
  ///
  /// Returns
  /// * a negative integer if [a] should precede [b],
  /// * zero if the order of [a] and [b] is irrelevant, and
  /// * a positive integer if [b] should precede [a].
  int _compare(SimpleSelectorSequence a, SimpleSelectorSequence b) {
    var x = a.simpleSelector;
    var y = b.simpleSelector;

    if (x.runtimeType == y.runtimeType) {
      if (x is ElementSelector || x is NamespaceSelector) {
        _logger.warning('Compound selector contains multiple type selectors:\n'
            '${x.span.message('')}\n'
            '${y.span.message('')}');
      } else if (x is PseudoElementSelector) {
        _logger.warning(
            'Compound selector contains multiple pseudo element selectors:\n'
            '${x.span.message('')}\n'
            '${y.span.message('')}');
      }
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
    var mergedSequences = merge([_sequences, sequences], _compare).toList()
        as List<SimpleSelectorSequence>;
    _sequences
      ..clear()
      ..addAll(mergedSequences);
  }

  CompoundSelector clone() {
    return new CompoundSelector()
      ..combinator = combinator
      .._sequences.addAll(_sequences.map((s) => s.clone()));
  }

  Iterable<SimpleSelectorSequence> toSequences() {
    if (_sequences.isNotEmpty) {
      _sequences.forEach(
          (sequence) => sequence.combinator = TokenKind.COMBINATOR_NONE);
      _sequences.first.combinator = combinator;
    }
    return _sequences;
  }
}

/// Shims selectors to emulate Shadow DOM CSS style encapsulation.
class ShadowTransformer extends Visitor {
  final String contentClass;
  final String hostClass;

  Set<SelectorGroup> _unscopedSelectorGroups;

  ShadowTransformer(this.contentClass, this.hostClass)
      : _unscopedSelectorGroups = new Set<SelectorGroup>();

  /// Selector groups in [unscopedSelectorGroups] aren't transformed.
  void visitTree(StyleSheet tree) {
    tree.visit(this);
    _unscopedSelectorGroups.clear();
  }

  /// Shimming :host-context() requires two selectors. One which matches the
  /// selector argument to the shadow host, and one which matches it against an
  /// ancestor. This method creates the latter, where the shadow host is a
  /// descendant. The former is handled by shimming the original selector
  /// itself.
  ///
  /// Example:
  ///   :host-context(.x) > .y  =>  .x :host > .y
  ComplexSelector _createDescendantHostSelectorFor(ComplexSelector selector) {
    var newSelector = new ComplexSelector();

    for (var compoundSelector in selector.compoundSelectors) {
      if (compoundSelector.containsHostContext) {
        var ancestor = new CompoundSelector()
          ..combinator = compoundSelector.combinator;
        var descendant = new CompoundSelector()
          ..combinator = TokenKind.COMBINATOR_DESCENDANT;
        var sequences = clone(compoundSelector.toSequences());

        for (var sequence in sequences) {
          var simpleSelector = sequence.simpleSelector;

          if (isHostContextFunction(simpleSelector)) {
            var hostContext = simpleSelector as PseudoClassFunctionSelector;
            ancestor.addAll(hostContext.selector.simpleSelectorSequences);
          } else {
            descendant.append(sequence);
          }
        }

        descendant.add(createPseudoClassSelectorSequence('host'));
        newSelector.compoundSelectors.add(ancestor);
        newSelector.compoundSelectors.add(descendant);
      } else {
        newSelector.compoundSelectors.add(compoundSelector.clone());
      }
    }

    return newSelector;
  }

  void shimPolyfillNextSelector(List<TreeNode> list) {
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
        } else if (matchesElement(
            node.selectorGroup, 'polyfill-next-selector')) {
          nextSelectorGroup =
              selectorGroupForProperty(node.declarationGroup, 'content');
        }
      }
    }

    // Remove 'polyfill-next-selector' rule sets.
    list.removeWhere((node) => node is RuleSet
        ? matchesElement(node.selectorGroup, 'polyfill-next-selector')
        : false);
  }

  void shimPolyfillUnscopedRule(RuleSet ruleSet) {
    if (matchesElement(ruleSet.selectorGroup, 'polyfill-unscoped-rule')) {
      var contentSelectorGroup = selectorGroupForProperty(
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

  /// Shims Shadow DOM CSS features to emulate style encapsulation.
  ///
  /// Example:
  ///   :host(.x) > .y >>> .z  =>  .x.host > .y.content .z
  void shimSelectors(ComplexSelector selector) {
    // Index of the first compound selector preceded by a shadow piercing
    // combinator.
    var deepIndex = selector.compoundSelectors.length;

    // Replace all shadow piercing combinators with descendant combinators.
    for (var i = deepIndex - 1; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];
      if (compoundSelector.combinator ==
              TokenKind.COMBINATOR_SHADOW_PIERCING_DESCENDANT ||
          compoundSelector.combinator == TokenKind.COMBINATOR_DEEP) {
        compoundSelector.combinator = TokenKind.COMBINATOR_DESCENDANT;
        deepIndex = i;
      }
    }

    // Index of the last compound selector which contains a host selector.
    var hostIndex = -1;

    // Scope all selectors between the last host selector and the first shadow
    // piercing combinator. We intentionally don't scope selectors BEFORE host
    // selectors for two reasons. Firstly, the :host-context() shim depends on
    // this behavior. Secondly, the shadow host could never possibly be a
    // descendant or sibling or its own content.
    for (var i = deepIndex - 1; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];
      if (compoundSelector.containsHost ||
          compoundSelector.containsHostContext) {
        hostIndex = i;
        break;
      }
      compoundSelector.add(createClassSelectorSequence(contentClass));
    }

    // Shim all host selectors.
    for (var i = hostIndex; i >= 0; i--) {
      var compoundSelector = selector.compoundSelectors[i];
      var selectorSequences = compoundSelector._sequences;

      for (var j = 0; j < selectorSequences.length; j++) {
        var selector = selectorSequences[j].simpleSelector;
        if (isHostFunction(selector) || isHostContextFunction(selector)) {
          // Replace :host() or :host-context() with host class.
          selectorSequences[j] = createClassSelectorSequence(hostClass);

          // Add :host() or :host-context() argument to constituent selector.
          var hostFn = selector as PseudoClassFunctionSelector;
          var hostArg = clone(hostFn.selector.simpleSelectorSequences);
          compoundSelector.addAll(hostArg);
        } else if (isHost(selector)) {
          // Replace :host with host class.
          selectorSequences[j] = createClassSelectorSequence(hostClass);
        }
      }
    }

    // Remove all ::content and ::shadow selectors.
    selector.compoundSelectors.forEach((compoundSelector) =>
        compoundSelector._sequences.removeWhere((sequence) {
          var selector = sequence.simpleSelector;
          return selector is PseudoElementSelector &&
              (selector.name == 'content' || selector.name == 'shadow');
        }));
  }

  visitDeclarationGroup(DeclarationGroup node) {
    shimPolyfillNextSelector(node.declarations);
    super.visitDeclarationGroup(node);
  }

  visitHostDirective(HostDirective node) {
    shimPolyfillNextSelector(node.rulesets);
    super.visitHostDirective(node);
  }

  visitMediaDirective(MediaDirective node) {
    shimPolyfillNextSelector(node.rulesets);
    super.visitMediaDirective(node);
  }

  visitMixinRulesetDirective(MixinRulesetDirective node) {
    shimPolyfillNextSelector(node.rulesets);
    super.visitMixinRulesetDirective(node);
  }

  visitRuleSet(RuleSet node) {
    shimPolyfillUnscopedRule(node);
    super.visitRuleSet(node);
  }

  visitSelectorGroup(SelectorGroup node) {
    if (_unscopedSelectorGroups.contains(node)) return;

    var complexSelectors = <ComplexSelector>[];
    for (var selector in node.selectors) {
      // Convert [Selector] to [ComplexSelector] to facilitate shimming
      // transformations.
      var complexSelector = new ComplexSelector.from(selector);
      complexSelectors.add(complexSelector);

      if (complexSelector.containsHostContext) {
        // Add a new selector which matches the host as a descendant of the
        // selector argument to :host-context().
        complexSelectors.add(_createDescendantHostSelectorFor(complexSelector));
      }
    }

    complexSelectors.forEach(shimSelectors);

    // Replace original selectors with shimmed selectors.
    node.selectors
      ..clear()
      ..addAll(complexSelectors.map((cs) => cs.toSelector()));
  }

  visitStyleSheet(StyleSheet node) {
    shimPolyfillNextSelector(node.topLevels);
    super.visitStyleSheet(node);
  }

  visitStyletDirective(StyletDirective node) {
    shimPolyfillNextSelector(node.rulesets);
    super.visitStyletDirective(node);
  }
}
