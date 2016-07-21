import "package:angular2/src/compiler/expression_parser/parser.dart"
    show Parser;
import "package:angular2/src/compiler/html_ast.dart"
    show
        HtmlAst,
        HtmlAstVisitor,
        HtmlElementAst,
        HtmlAttrAst,
        HtmlTextAst,
        HtmlCommentAst,
        HtmlExpansionAst,
        HtmlExpansionCaseAst,
        htmlVisitAll;
import "package:angular2/src/compiler/html_parser.dart"
    show HtmlParser, HtmlParseTreeResult;
import "package:angular2/src/compiler/parse_util.dart"
    show ParseSourceSpan, ParseError;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:angular2/src/facade/lang.dart"
    show RegExpWrapper, NumberWrapper, isPresent;

import "expander.dart" show expandNodes;
import "message.dart" show id;
import "shared.dart"
    show
        messageFromAttribute,
        I18nError,
        I18N_ATTR_PREFIX,
        I18N_ATTR,
        partition,
        Part,
        getPhNameFromBinding,
        dedupePhName;

const _I18N_ATTR = "i18n";
const _PLACEHOLDER_ELEMENT = "ph";
const _NAME_ATTR = "name";
const _I18N_ATTR_PREFIX = "i18n-";
var _PLACEHOLDER_EXPANDED_REGEXP =
    RegExpWrapper.create('''\\<ph(\\s)+name=("(\\w)+")\\>\\<\\/ph\\>''');

/**
 * Creates an i18n-ed version of the parsed template.
 *
 * Algorithm:
 *
 * To understand the algorithm, you need to know how partitioning works.
 * Partitioning is required as we can use two i18n comments to group node siblings together.
 * That is why we cannot just use nodes.
 *
 * Partitioning transforms an array of HtmlAst into an array of Part.
 * A part can optionally contain a root element or a root text node. And it can also contain
 * children.
 * A part can contain i18n property, in which case it needs to be transalted.
 *
 * Example:
 *
 * The following array of nodes will be split into four parts:
 *
 * ```
 * <a>A</a>
 * <b i18n>B</b>
 * <!-- i18n -->
 * <c>C</c>
 * D
 * <!-- /i18n -->
 * E
 * ```
 *
 * Part 1 containing the a tag. It should not be translated.
 * Part 2 containing the b tag. It should be translated.
 * Part 3 containing the c tag and the D text node. It should be translated.
 * Part 4 containing the E text node. It should not be translated.
 *
 *
 * It is also important to understand how we stringify nodes to create a message.
 *
 * We walk the tree and replace every element node with a placeholder. We also replace
 * all expressions in interpolation with placeholders. We also insert a placeholder element
 * to wrap a text node containing interpolation.
 *
 * Example:
 *
 * The following tree:
 *
 * ```
 * <a>A{{I}}</a><b>B</b>
 * ```
 *
 * will be stringified into:
 * ```
 * <ph name="e0"><ph name="t1">A<ph name="0"/></ph></ph><ph name="e2">B</ph>
 * ```
 *
 * This is what the algorithm does:
 *
 * 1. Use the provided html parser to get the html AST of the template.
 * 2. Partition the root nodes, and process each part separately.
 * 3. If a part does not have the i18n attribute, recurse to process children and attributes.
 * 4. If a part has the i18n attribute, merge the translated i18n part with the original tree.
 *
 * This is how the merging works:
 *
 * 1. Use the stringify function to get the message id. Look up the message in the map.
 * 2. Get the translated message. At this point we have two trees: the original tree
 * and the translated tree, where all the elements are replaced with placeholders.
 * 3. Use the original tree to create a mapping Index:number -> HtmlAst.
 * 4. Walk the translated tree.
 * 5. If we encounter a placeholder element, get is name property.
 * 6. Get the type and the index of the node using the name property.
 * 7. If the type is 'e', which means element, then:
 *     - translate the attributes of the original element
 *     - recurse to merge the children
 *     - create a new element using the original element name, original position,
 *     and translated children and attributes
 * 8. If the type if 't', which means text, then:
 *     - get the list of expressions from the original node.
 *     - get the string version of the interpolation subtree
 *     - find all the placeholders in the translated message, and replace them with the
 *     corresponding original expressions
 */
class I18nHtmlParser implements HtmlParser {
  HtmlParser _htmlParser;
  Parser _parser;
  String _messagesContent;
  Map<String, List<HtmlAst>> _messages;
  List<ParseError> errors;
  I18nHtmlParser(
      this._htmlParser, this._parser, this._messagesContent, this._messages) {}
  HtmlParseTreeResult parse(String sourceContent, String sourceUrl,
      [bool parseExpansionForms = false]) {
    this.errors = [];
    var res = this._htmlParser.parse(sourceContent, sourceUrl, true);
    if (res.errors.length > 0) {
      return res;
    } else {
      var nodes = this._recurse(expandNodes(res.rootNodes).nodes);
      return this.errors.length > 0
          ? new HtmlParseTreeResult([], this.errors)
          : new HtmlParseTreeResult(nodes, []);
    }
  }

  List<HtmlAst> _processI18nPart(Part p) {
    try {
      return p.hasI18n ? this._mergeI18Part(p) : this._recurseIntoI18nPart(p);
    } catch (e) {
      if (e is I18nError) {
        this.errors.add(e);
        return [];
      } else {
        rethrow;
      }
    }
  }

  List<HtmlAst> _mergeI18Part(Part p) {
    var message = p.createMessage(this._parser);
    var messageId = id(message);
    if (!StringMapWrapper.contains(this._messages, messageId)) {
      throw new I18nError(p.sourceSpan,
          '''Cannot find message for id \'${ messageId}\', content \'${ message . content}\'.''');
    }
    var parsedMessage = this._messages[messageId];
    return this._mergeTrees(p, parsedMessage, p.children);
  }

  List<HtmlAst> _recurseIntoI18nPart(Part p) {
    // we found an element without an i18n attribute

    // we need to recurse in cause its children may have i18n set

    // we also need to translate its attributes
    if (isPresent(p.rootElement)) {
      var root = p.rootElement;
      var children = this._recurse(p.children);
      var attrs = this._i18nAttributes(root);
      return [
        new HtmlElementAst(root.name, attrs, children, root.sourceSpan,
            root.startSourceSpan, root.endSourceSpan)
      ];
    } else if (isPresent(p.rootTextNode)) {
      return [p.rootTextNode];
    } else {
      return this._recurse(p.children);
    }
  }

  List<HtmlAst> _recurse(List<HtmlAst> nodes) {
    var ps = partition(nodes, this.errors);
    return ListWrapper.flatten(ps.map((p) => this._processI18nPart(p)).toList())
        as List<HtmlAst>;
  }

  List<HtmlAst> _mergeTrees(
      Part p, List<HtmlAst> translated, List<HtmlAst> original) {
    var l = new _CreateNodeMapping();
    htmlVisitAll(l, original);
    // merge the translated tree with the original tree.

    // we do it by preserving the source code position of the original tree
    var merged = this._mergeTreesHelper(translated, l.mapping);
    // if the root element is present, we need to create a new root element with its attributes

    // translated
    if (isPresent(p.rootElement)) {
      var root = p.rootElement;
      var attrs = this._i18nAttributes(root);
      return [
        new HtmlElementAst(root.name, attrs, merged, root.sourceSpan,
            root.startSourceSpan, root.endSourceSpan)
      ];
    } else if (isPresent(p.rootTextNode)) {
      throw new BaseException("should not be reached");
    } else {
      return merged;
    }
  }

  List<HtmlAst> _mergeTreesHelper(
      List<HtmlAst> translated, List<HtmlAst> mapping) {
    return translated.map((t) {
      if (t is HtmlElementAst) {
        return this._mergeElementOrInterpolation(t, translated, mapping);
      } else if (t is HtmlTextAst) {
        return t;
      } else {
        throw new BaseException("should not be reached");
      }
    }).toList();
  }

  HtmlAst _mergeElementOrInterpolation(
      HtmlElementAst t, List<HtmlAst> translated, List<HtmlAst> mapping) {
    var name = this._getName(t);
    var type = name[0];
    var index = NumberWrapper.parseInt(name.substring(1), 10);
    var originalNode = mapping[index];
    if (type == "t") {
      return this._mergeTextInterpolation(t, (originalNode as HtmlTextAst));
    } else if (type == "e") {
      return this._mergeElement(t, (originalNode as HtmlElementAst), mapping);
    } else {
      throw new BaseException("should not be reached");
    }
  }

  String _getName(HtmlElementAst t) {
    if (t.name != _PLACEHOLDER_ELEMENT) {
      throw new I18nError(t.sourceSpan,
          '''Unexpected tag "${ t . name}". Only "${ _PLACEHOLDER_ELEMENT}" tags are allowed.''');
    }
    var names = t.attrs.where((a) => a.name == _NAME_ATTR).toList();
    if (names.length == 0) {
      throw new I18nError(
          t.sourceSpan, '''Missing "${ _NAME_ATTR}" attribute.''');
    }
    return names[0].value;
  }

  HtmlTextAst _mergeTextInterpolation(
      HtmlElementAst t, HtmlTextAst originalNode) {
    var split = this._parser.splitInterpolation(
        originalNode.value, originalNode.sourceSpan.toString());
    List<String> exps = split?.expressions ?? <String>[];
    var messageSubstring = this
        ._messagesContent
        .substring(t.startSourceSpan.end.offset, t.endSourceSpan.start.offset);
    var translated = this._replacePlaceholdersWithExpressions(
        messageSubstring, exps, originalNode.sourceSpan);
    return new HtmlTextAst(translated, originalNode.sourceSpan);
  }

  HtmlElementAst _mergeElement(
      HtmlElementAst t, HtmlElementAst originalNode, List<HtmlAst> mapping) {
    var children = this._mergeTreesHelper(t.children, mapping);
    return new HtmlElementAst(
        originalNode.name,
        this._i18nAttributes(originalNode),
        children,
        originalNode.sourceSpan,
        originalNode.startSourceSpan,
        originalNode.endSourceSpan);
  }

  List<HtmlAttrAst> _i18nAttributes(HtmlElementAst el) {
    var res = <HtmlAttrAst>[];
    el.attrs.forEach((attr) {
      if (attr.name.startsWith(I18N_ATTR_PREFIX) || attr.name == I18N_ATTR)
        return;
      var i18ns =
          el.attrs.where((a) => a.name == '''i18n-${ attr . name}''').toList();
      if (i18ns.length == 0) {
        res.add(attr);
        return;
      }
      var i18n = i18ns[0];
      var message = messageFromAttribute(this._parser, el, i18n);
      var messageId = id(message);
      if (StringMapWrapper.contains(this._messages, messageId)) {
        var updatedMessage =
            this._replaceInterpolationInAttr(attr, this._messages[messageId]);
        res.add(new HtmlAttrAst(attr.name, updatedMessage, attr.sourceSpan));
      } else {
        throw new I18nError(attr.sourceSpan,
            '''Cannot find message for id \'${ messageId}\', content \'${ message . content}\'.''');
      }
    });
    return res;
  }

  String _replaceInterpolationInAttr(HtmlAttrAst attr, List<HtmlAst> msg) {
    var split =
        this._parser.splitInterpolation(attr.value, attr.sourceSpan.toString());
    List<String> exps = split?.expressions ?? [];
    var first = msg[0];
    var last = msg[msg.length - 1];
    var start = first.sourceSpan.start.offset;
    var end = last is HtmlElementAst
        ? last.endSourceSpan.end.offset
        : last.sourceSpan.end.offset;
    var messageSubstring = this._messagesContent.substring(start, end);
    return this._replacePlaceholdersWithExpressions(
        messageSubstring, exps, attr.sourceSpan);
  }

  String _replacePlaceholdersWithExpressions(
      String message, List<String> exps, ParseSourceSpan sourceSpan) {
    var expMap = this._buildExprMap(exps);
    return RegExpWrapper.replaceAll(_PLACEHOLDER_EXPANDED_REGEXP, message,
        (match) {
      var nameWithQuotes = match[2];
      var name = nameWithQuotes.substring(1, nameWithQuotes.length - 1);
      return this._convertIntoExpression(name, expMap, sourceSpan);
    });
  }

  Map<String, String> _buildExprMap(List<String> exps) {
    var expMap = new Map<String, String>();
    var usedNames = new Map<String, num>();
    for (var i = 0; i < exps.length; i++) {
      var phName = getPhNameFromBinding(exps[i], i);
      expMap[dedupePhName(usedNames, phName)] = exps[i];
    }
    return expMap;
  }

  _convertIntoExpression(
      String name, Map<String, String> expMap, ParseSourceSpan sourceSpan) {
    if (expMap.containsKey(name)) {
      return '''{{${ expMap [ name ]}}}''';
    } else {
      throw new I18nError(
          sourceSpan, '''Invalid interpolation name \'${ name}\'''');
    }
  }
}

class _CreateNodeMapping implements HtmlAstVisitor {
  List<HtmlAst> mapping = [];
  dynamic visitElement(HtmlElementAst ast, dynamic context) {
    this.mapping.add(ast);
    htmlVisitAll(this, ast.children);
    return null;
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    return null;
  }

  dynamic visitText(HtmlTextAst ast, dynamic context) {
    this.mapping.add(ast);
    return null;
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    return null;
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    return null;
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return "";
  }
}
