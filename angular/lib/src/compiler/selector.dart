import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:tuple/tuple.dart';

import 'attribute_matcher.dart';
import 'html_tags.dart' show getHtmlTagDefinition;

final _SELECTOR_REGEXP = new RegExp(r'(:not\()|' + // ":not("
        r'([-\w]+)|' + // "tag-name"
        r'(?:\.([-\w]+))|' + // ".class"
        // <attr-matcher> := [ '~' | '|' | '^' | '$' | '*' ]? '='
        // <attr-selector> := '[' <name> ']' |
        //                    '[' <name> <attr-matcher> <value> ']'
        '(?:\\[([-\\w]+)(?:([~|^\$*]?=)([\'"]?)([^\\]\'"]*)\\6)?\\])|' +
        r'(\))|' + // ")"
        r'(\s*,\s*)' // ","
    );

/// A css selector contains an element name,
/// css classes and attribute/value pairs with the purpose
/// of selecting subsets out of them.
class CssSelector {
  String element;
  final List<String> classNames = [];
  final List<AttributeMatcher> attrs = [];
  final List<CssSelector> notSelectors = [];
  static List<CssSelector> parse(String selector) {
    List<CssSelector> results = [];
    var _addResult = (List<CssSelector> res, CssSelector cssSel) {
      if (cssSel.notSelectors.length > 0 &&
          cssSel.element == null &&
          cssSel.classNames.isEmpty &&
          cssSel.attrs.isEmpty) {
        cssSel.element = "*";
      }
      res.add(cssSel);
    };
    var cssSelector = new CssSelector();
    var matcher = _SELECTOR_REGEXP.allMatches(selector);
    var current = cssSelector;
    var inNot = false;
    for (var match in matcher) {
      if (match == null) break;
      if (match[1] != null) {
        if (inNot) {
          throw new BaseException("Nesting :not is not allowed in a selector");
        }
        inNot = true;
        current = new CssSelector();
        cssSelector.notSelectors.add(current);
      }
      if (match[2] != null) {
        current.setElement(match[2]);
      }
      if (match[3] != null) {
        current.addClassName(match[3]);
      }
      if (match[4] != null) {
        current.addAttribute(match[4], match[5], match[7]);
      }
      if (match[8] != null) {
        inNot = false;
        current = cssSelector;
      }
      if (match[9] != null) {
        if (inNot) {
          throw new BaseException(
              "Multiple selectors in :not are not supported");
        }
        _addResult(results, cssSelector);
        cssSelector = current = new CssSelector();
      }
    }
    _addResult(results, cssSelector);
    return results;
  }

  bool isElementSelector() {
    return element != null &&
        classNames.isEmpty &&
        attrs.isEmpty &&
        notSelectors.isEmpty;
  }

  void setElement([String element]) {
    this.element = element;
  }

  /// Gets a template string for an element that matches the selector.
  String getMatchingElementTemplate() {
    final attributeBuffer = new StringBuffer();
    final tagName = element ?? 'div';

    if (classNames.isNotEmpty) {
      attributeBuffer
        ..write(' class="')
        ..write(classNames.join(' '))
        ..write('"');
    }

    for (var attr in attrs) {
      attributeBuffer..write(' ')..write(attr.name);
      if (attr.value != null) {
        attributeBuffer..write('="')..write(attr.value)..write('"');
      }
    }
    return (getHtmlTagDefinition(tagName).isVoid)
        ? '<$tagName$attributeBuffer>'
        : '<$tagName$attributeBuffer></$tagName>';
  }

  void addAttribute(String name, String matcher, String value) {
    value = value?.toLowerCase();
    if (matcher == null) {
      attrs.add(new SetAttributeMatcher(name));
    } else if (matcher == '=') {
      attrs.add(new ExactAttributeMatcher(name, value));
    } else if (value.isNotEmpty) {
      // The following attribute selectors match nothing if the attribute value
      // is the empty string, so we only add them if they can match.
      switch (matcher) {
        case '~=':
          attrs.add(new ListAttributeMatcher(name, value));
          break;
        case '|=':
          attrs.add(new HyphenAttributeMatcher(name, value));
          break;
        case '^=':
          attrs.add(new PrefixAttributeMatcher(name, value));
          break;
        case r'$=':
          attrs.add(new SuffixAttributeMatcher(name, value));
          break;
        case '*=':
          attrs.add(new SubstringAttributeMatcher(name, value));
          break;
      }
    }
  }

  void addClassName(String name) {
    this.classNames.add(name.toLowerCase());
  }

  String toString() {
    final sb = new StringBuffer();
    if (element != null) {
      sb.write(element);
    }
    for (var className in classNames) {
      sb.write('.');
      sb.write(className);
    }
    for (var attr in attrs) {
      sb.write(attr);
    }
    for (var notSelector in notSelectors) {
      sb.write(':not(');
      sb.write(notSelector);
      sb.write(')');
    }
    return sb.toString();
  }
}

/// Reads a list of CssSelectors and allows to calculate which ones
/// are contained in a given CssSelector.
class SelectorMatcher {
  static SelectorMatcher createNotMatcher(List<CssSelector> notSelectors) {
    var notMatcher = new SelectorMatcher();
    notMatcher.addSelectables(notSelectors, null);
    return notMatcher;
  }

  final _elementMap = new Map<String, List<SelectorContext>>();
  final _elementPartialMap = new Map<String, SelectorMatcher>();
  final _classMap = new Map<String, List<SelectorContext>>();
  final _classPartialMap = new Map<String, SelectorMatcher>();
  final _attrMatchers =
      <String, List<Tuple2<AttributeMatcher, SelectorContext>>>{};
  final _attrPartialMatchers =
      <String, List<Tuple2<AttributeMatcher, SelectorMatcher>>>{};
  final _listContexts = <SelectorListContext>[];

  void addSelectables(List<CssSelector> cssSelectors, [dynamic callbackCtxt]) {
    var listContext;
    if (cssSelectors.length > 1) {
      listContext = new SelectorListContext(cssSelectors);
      this._listContexts.add(listContext);
    }
    for (var i = 0; i < cssSelectors.length; i++) {
      this._addSelectable(cssSelectors[i], callbackCtxt, listContext);
    }
  }

  /// Add an object that can be found later on by calling `match`.
  void _addSelectable(CssSelector cssSelector, dynamic callbackCtxt,
      SelectorListContext listContext) {
    SelectorMatcher matcher = this;
    var element = cssSelector.element;
    var classNames = cssSelector.classNames;
    var attrs = cssSelector.attrs;
    var selectable =
        new SelectorContext(cssSelector, callbackCtxt, listContext);
    if (element != null) {
      var isTerminal =
          identical(attrs.length, 0) && identical(classNames.length, 0);
      if (isTerminal) {
        this._addTerminal(matcher._elementMap, element, selectable);
      } else {
        matcher = this._addPartial(matcher._elementPartialMap, element);
      }
    }
    for (var index = 0; index < classNames.length; index++) {
      var isTerminal =
          identical(attrs.length, 0) && identical(index, classNames.length - 1);
      var className = classNames[index];
      if (isTerminal) {
        this._addTerminal(matcher._classMap, className, selectable);
      } else {
        matcher = this._addPartial(matcher._classPartialMap, className);
      }
    }
    for (var attrMatcher in attrs) {
      if (identical(attrMatcher, attrs.last)) {
        final matchers = matcher._attrMatchers[attrMatcher.name] ??= [];
        matchers.add(new Tuple2<AttributeMatcher, SelectorContext>(
            attrMatcher, selectable));
      } else {
        final matchers = matcher._attrPartialMatchers[attrMatcher.name] ??= [];
        final newMatcher = new SelectorMatcher();
        matchers.add(new Tuple2<AttributeMatcher, SelectorMatcher>(
            attrMatcher, newMatcher));
        matcher = newMatcher;
      }
    }
  }

  void _addTerminal(Map<String, List<SelectorContext>> map, String name,
      SelectorContext selectable) {
    var terminalList = map[name];
    if (terminalList == null) {
      terminalList = [];
      map[name] = terminalList;
    }
    terminalList.add(selectable);
  }

  SelectorMatcher _addPartial(Map<String, SelectorMatcher> map, String name) {
    var matcher = map[name];
    if (matcher == null) {
      matcher = new SelectorMatcher();
      map[name] = matcher;
    }
    return matcher;
  }

  /// Find the objects that have been added via `addSelectable`
  /// whose css selector is contained in the given css selector.
  bool match(
      CssSelector cssSelector, void matchedCallback(CssSelector c, dynamic a)) {
    var result = false;
    var element = cssSelector.element;
    var classNames = cssSelector.classNames;
    for (var i = 0; i < this._listContexts.length; i++) {
      this._listContexts[i].alreadyMatched = false;
    }
    result = this._matchTerminal(
            this._elementMap, element, cssSelector, matchedCallback) ||
        result;
    result = this._matchPartial(
            this._elementPartialMap, element, cssSelector, matchedCallback) ||
        result;
    for (var index = 0; index < classNames.length; index++) {
      var className = classNames[index];
      result = this._matchTerminal(
              this._classMap, className, cssSelector, matchedCallback) ||
          result;
      result = this._matchPartial(
              this._classPartialMap, className, cssSelector, matchedCallback) ||
          result;
    }
    for (var attr in cssSelector.attrs) {
      final attrMatchers = _attrMatchers[attr.name];
      if (attrMatchers != null) {
        for (var pair in attrMatchers) {
          if (pair.item1.matches(attr.value)) {
            result =
                pair.item2.finalize(cssSelector, matchedCallback) || result;
          }
        }
      }
      final attrPartialMatchers = _attrPartialMatchers[attr.name];
      if (attrPartialMatchers != null) {
        for (var pair in attrPartialMatchers) {
          if (pair.item1.matches(attr.value)) {
            result = pair.item2.match(cssSelector, matchedCallback) || result;
          }
        }
      }
    }
    return result;
  }

  bool _matchTerminal(Map<String, List<SelectorContext>> map, name,
      CssSelector cssSelector, void matchedCallback(CssSelector c, dynamic a)) {
    if (map == null || name == null) {
      return false;
    }
    var selectables = map[name];
    var starSelectables = map["*"];
    if (starSelectables != null) {
      selectables = (new List.from(selectables)..addAll(starSelectables));
    }
    if (selectables == null) {
      return false;
    }
    var selectable;
    var result = false;
    for (var index = 0; index < selectables.length; index++) {
      selectable = selectables[index];
      result = selectable.finalize(cssSelector, matchedCallback) || result;
    }
    return result;
  }

  bool _matchPartial(Map<String, SelectorMatcher> map, name,
      CssSelector cssSelector, void matchedCallback(CssSelector c, dynamic a)) {
    if (map == null || name == null) {
      return false;
    }
    var nestedSelector = map[name];
    if (nestedSelector == null) {
      return false;
    }
    // TODO(perf): get rid of recursion and measure again

    // TODO(perf): don't pass the whole selector into the recursion,

    // but only the not processed parts
    return nestedSelector.match(cssSelector, matchedCallback);
  }
}

class SelectorListContext {
  List<CssSelector> selectors;
  bool alreadyMatched = false;
  SelectorListContext(this.selectors);
}

// Store context to pass back selector and context when a selector is matched
class SelectorContext {
  CssSelector selector;
  dynamic cbContext;
  SelectorListContext listContext;
  List<CssSelector> notSelectors;
  SelectorContext(this.selector, this.cbContext, this.listContext) {
    this.notSelectors = selector.notSelectors;
  }
  bool finalize(
      CssSelector cssSelector, void callback(CssSelector c, dynamic a)) {
    var result = true;
    if (this.notSelectors.length > 0 &&
        (this.listContext == null || !this.listContext.alreadyMatched)) {
      var notMatcher = SelectorMatcher.createNotMatcher(this.notSelectors);
      result = !notMatcher.match(cssSelector, null);
    }
    if (result &&
        callback != null &&
        (this.listContext == null || !this.listContext.alreadyMatched)) {
      if (listContext != null) {
        listContext.alreadyMatched = true;
      }
      callback(this.selector, this.cbContext);
    }
    return result;
  }
}
