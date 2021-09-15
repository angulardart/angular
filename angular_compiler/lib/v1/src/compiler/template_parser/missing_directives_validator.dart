import 'package:angular_compiler/v1/src/compiler/aria_attributes.dart';
import 'package:angular_compiler/v1/src/compiler/html_events.dart';
import 'package:angular_compiler/v1/src/compiler/schema/element_schema_registry.dart';
import 'package:angular_compiler/v1/src/compiler/schema/skip_selectors_validator.dart';
import 'package:angular_compiler/v1/src/compiler/selector.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart' as ng;
import 'package:angular_compiler/v1/src/compiler/template_parser/recursive_template_visitor.dart';
import 'package:angular_compiler/v1/src/compiler/view_compiler/view_compiler_utils.dart';
import 'package:angular_compiler/v2/context.dart';

const String optedOutValidator = 'If your project uses selector css styling '
    'heavily, or the templates contain external custom elements not supported by '
    'ACX, then this feature might not be a good fit for your project. To prevent '
    'compilation errors, please add your project to the disallow list in '
    'go/opted-out-missing-directive-validator';

/// A validator to catch missing elements, direcitves, attributes, and outputs.
///
/// Issue a warning when @skipSchemaValidationFor annotation not found and
///
/// * an unknown tag cannot find a matched directive.
/// * an attribute is neither a valid native property in HTML5, or an input
///   binding for an element, or a matched directive.
/// * an output is neither a native event or an output binding for an element.
class MissingDirectiveValidator
    extends InPlaceRecursiveTemplateVisitor<_MissingDirectiveContext> {
  final ElementSchemaRegistry _registry;

  static const _testAttributes = {
    'debugid',
    'debug-id',
    'debugId',
    'data-test-id'
  };

  MissingDirectiveValidator(this._registry);

  @override
  void visitElement(ng.ElementAst ast, [_]) {
    final selectorsGroup = _selectorsGroup(ast.directives);
    final skipValidationSelectors =
        CssSelector.parse(ast.skipSchemaValidationForSelector);
    // checks whether a selector in @skipSchemaValidationFor is unused.
    if (ast.skipSchemaValidationForSelector.isNotEmpty &&
        _hasUnusedSelector(ast, skipValidationSelectors)) {
      CompileContext.current.reportAndRecover(
        BuildError.forSourceSpan(
          ast.sourceSpan,
          'A selector in @skipSchemaValidationFor="'
          '${ast.skipSchemaValidationForSelector}" does not match this '
          'element.\n$optedOutValidator',
        ),
      );
    }
    final elementName = _extractXhtml(ast.name);
    if (!(_matchedSelectorWithElement(skipValidationSelectors, elementName) ||
        detectHtmlElementFromTagName(elementName) ||
        _hasMatchedSelector(selectorsGroup, elementName) ||
        _matchedSelectorWithElement(
            ast.matchedNgContentSelectors, elementName) ||
        hasElementInAllowlist(elementName) ||
        elementName.startsWith('@svg'))) {
      CompileContext.current.reportAndRecover(
        BuildError.forSourceSpan(
          ast.sourceSpan,
          "Can't find '<$elementName>'. Please check that the spelling "
          'is correct, and that the intended component is included in the '
          "host component's list of directives. "
          'See more details go/skipschemavalidationfor.\n$optedOutValidator',
        ),
      );
    }
    super.visitElement(
      ast,
      _MissingDirectiveContext(
        elementName,
        ast.directives,
        selectorsGroup,
        ast.matchedNgContentSelectors,
        skipValidationSelectors,
        attributeDeps: ast.attributeDeps,
      ),
    );
  }

  CssSelector _createElementSelector(ng.ElementAst astNode) {
    var selector = CssSelector();
    selector.setElement(astNode.name);
    for (var attr in astNode.attrs) {
      selector.addAttribute(attr.name, null, null);
    }
    for (var output in astNode.outputs) {
      selector.addAttribute(output.name, null, null);
    }
    return selector;
  }

  bool _hasUnusedSelector(
    ng.ElementAst astNode,
    List<CssSelector> skipValidationSelectors,
  ) {
    final elementSelector = _createElementSelector(astNode);
    return !skipValidationSelectors.every((selector) {
      var matcher = SelectorMatcher<void>();
      matcher.addSelectables([selector], null);
      return matcher.match(elementSelector, null);
    });
  }

  static Iterable<List<CssSelector>> _selectorsGroup(
    List<ng.DirectiveAst> directives,
  ) =>
      directives.map(
        (directive) => CssSelector.parse(directive.directive.selector!),
      );

  static bool _hasMatchedSelector(
    Iterable<List<CssSelector>> selectorsGroup,
    String name,
  ) =>
      selectorsGroup.any(
        (selectors) => selectors.any((selector) => selector.element == name),
      );

  static bool _matchedSelectorWithElement(
    List<CssSelector> selectors,
    String name,
  ) =>
      selectors.any((selector) => selector.element == name);

  @override
  void visitEmbeddedTemplate(ng.EmbeddedTemplateAst ast, [_]) {
    final selectorsGroup = _selectorsGroup(ast.directives);
    super.visitEmbeddedTemplate(
      ast,
      _MissingDirectiveContext(
        'template',
        ast.directives,
        selectorsGroup,
        ast.matchedNgContentSelectors,
        [],
      ),
    );
  }

  @override
  void visitAttr(ng.AttrAst ast, [_MissingDirectiveContext? context]) {
    if (context!.elementName.startsWith('@svg')) {
      return;
    }
    if (!(_matchedSelectorWithAttribute(
            context.skipValidationSelectors, ast.name) ||
        _registry.hasAttribute(context.elementName, ast.name) ||
        _matchesInput(context.directives, ast.name) ||
        _matchedDirectiveWithAttribute(context.selectorsGroup, ast.name) ||
        _matchedSelectorWithAttribute(
            context.matchedNgContentSelectors, ast.name) ||
        hasAttributeInAllowlist(context.elementName, ast.name) ||
        isAriaAttribute(ast.name) ||
        context.attributeDeps.contains(ast.name) ||
        _isTestAttribute(ast.name))) {
      CompileContext.current.reportAndRecover(
        BuildError.forSourceSpan(
          ast.sourceSpan,
          "Can't bind to '${ast.name}' since it isn't an input of any "
          'bound directive or a native property. Please check that the '
          'spelling is correct, or that the intended directive is included '
          "in the host component's list of directives. "
          'See more details go/skipschemavalidationfor.\n$optedOutValidator',
        ),
      );
    }
  }

  static bool _matchesInput(List<ng.DirectiveAst> directives, String name) {
    for (var directive in directives) {
      for (var directiveName in directive.directive.inputs.keys) {
        var templateName = directive.directive.inputs[directiveName];
        if (templateName == name) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _matchedDirectiveWithAttribute(
    Iterable<List<CssSelector>> selectorsGroup,
    String name,
  ) =>
      selectorsGroup.any(
        (selectors) => selectors.any(
          (selector) => selector.attrs.any((matcher) => matcher.name == name),
        ),
      );

  static bool _matchedSelectorWithAttribute(
    List<CssSelector> selectors,
    String name,
  ) =>
      selectors.any(
        (selector) => selector.attrs.any((matcher) => matcher.name == name),
      );

  static bool _isTestAttribute(String name) => _testAttributes.contains(name);

  static String _extractXhtml(String selector) =>
      selector.replaceFirst('@xhtml:', '');

  @override
  void visitEvent(ng.BoundEventAst ast, [_MissingDirectiveContext? context]) {
    var name = _extractEventName(ast.name);
    if (!(_matchedSelectorWithAttribute(
            context!.skipValidationSelectors, ast.name) ||
        // HTML events are not case sensitive.
        isNativeHtmlEvent(name.toLowerCase()) ||
        _registry.hasEvent(context.elementName, name) ||
        hasEventInAllowlist(context.elementName, ast.name))) {
      CompileContext.current.reportAndRecover(
        BuildError.forSourceSpan(
          ast.sourceSpan,
          "Can't bind to ($name) since it isn't an output "
          'of any bound directive or a native event. Please check '
          'that the spelling is correct, and that the intended '
          "directive is included in the host component's list of "
          'directives. See more details go/skipschemavalidationfor.\n'
          '$optedOutValidator',
        ),
      );
    }
  }

  static String _extractEventName(String name) => name.split('.').first;
}

class _MissingDirectiveContext {
  final String elementName;
  final List<ng.DirectiveAst> directives;
  final Iterable<List<CssSelector>> selectorsGroup;
  final List<CssSelector> matchedNgContentSelectors;
  final List<CssSelector> skipValidationSelectors;
  final Set<String> attributeDeps;

  _MissingDirectiveContext(
    this.elementName,
    this.directives,
    this.selectorsGroup,
    this.matchedNgContentSelectors,
    this.skipValidationSelectors, {
    this.attributeDeps = const {},
  });
}
