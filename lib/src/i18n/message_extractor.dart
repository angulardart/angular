import "package:angular2/src/compiler/expression_parser/parser.dart"
    show Parser;
import "package:angular2/src/compiler/html_ast.dart"
    show HtmlAst, HtmlElementAst;
import "package:angular2/src/compiler/html_parser.dart" show HtmlParser;
import "package:angular2/src/compiler/parse_util.dart" show ParseError;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isPresent;

import "expander.dart" show expandNodes;
import "message.dart" show Message, id;
import "shared.dart"
    show I18nError, Part, I18N_ATTR_PREFIX, partition, messageFromAttribute;

/**
 * All messages extracted from a template.
 */
class ExtractionResult {
  List<Message> messages;
  List<ParseError> errors;
  ExtractionResult(this.messages, this.errors) {}
}

/**
 * Removes duplicate messages.
 *
 * E.g.
 *
 * ```
 *  var m = [new Message("message", "meaning", "desc1"), new Message("message", "meaning",
 * "desc2")];
 *  expect(removeDuplicates(m)).toEqual([new Message("message", "meaning", "desc1")]);
 * ```
 */
List<Message> removeDuplicates(List<Message> messages) {
  var uniq = <String, Message>{};
  messages.forEach((m) {
    if (!StringMapWrapper.contains(uniq, id(m))) {
      uniq[id(m)] = m;
    }
  });
  return uniq.values;
}

/**
 * Extracts all messages from a template.
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
 * A part can contain i18n property, in which case it needs to be extracted.
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
 * Part 4 containing the E text node. It should not be translated..
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
 * 4. If a part has the i18n attribute, stringify the nodes to create a Message.
 */
class MessageExtractor {
  HtmlParser _htmlParser;
  Parser _parser;
  List<Message> messages;
  List<ParseError> errors;
  MessageExtractor(this._htmlParser, this._parser) {}
  ExtractionResult extract(String template, String sourceUrl) {
    this.messages = [];
    this.errors = [];
    var res = this._htmlParser.parse(template, sourceUrl, true);
    if (res.errors.length > 0) {
      return new ExtractionResult([], res.errors);
    } else {
      this._recurse(expandNodes(res.rootNodes).nodes);
      return new ExtractionResult(this.messages, this.errors);
    }
  }

  void _extractMessagesFromPart(Part p) {
    if (p.hasI18n) {
      messages.add(p.createMessage(_parser));
      _recurseToExtractMessagesFromAttributes(p.children);
    } else {
      _recurse(p.children);
    }
    var rootElement = p.rootElement;
    if (rootElement != null) {
      _extractMessagesFromAttributes(rootElement);
    }
  }

  void _recurse(List<HtmlAst> nodes) {
    if (isPresent(nodes)) {
      var ps = partition(nodes, this.errors);
      ps.forEach((p) => this._extractMessagesFromPart(p));
    }
  }

  void _recurseToExtractMessagesFromAttributes(List<HtmlAst> nodes) {
    nodes.forEach((n) {
      if (n is HtmlElementAst) {
        this._extractMessagesFromAttributes(n);
        this._recurseToExtractMessagesFromAttributes(n.children);
      }
    });
  }

  void _extractMessagesFromAttributes(HtmlElementAst p) {
    p.attrs.forEach((attr) {
      if (attr.name.startsWith(I18N_ATTR_PREFIX)) {
        try {
          this.messages.add(messageFromAttribute(this._parser, p, attr));
        } catch (e) {
          if (e is I18nError) {
            this.errors.add(e);
          } else {
            rethrow;
          }
        }
      }
    });
  }
}
