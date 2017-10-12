import 'html_ast.dart' show HtmlElementAst;
import 'html_tags.dart' show splitNsName;

const NG_CONTENT_SELECT_ATTR = 'select';
const NG_CONTENT_ELEMENT = 'ng-content';
const LINK_ELEMENT = 'link';
const LINK_STYLE_REL_ATTR = 'rel';
const LINK_STYLE_HREF_ATTR = 'href';
const LINK_STYLE_REL_VALUE = 'stylesheet';
const STYLE_ELEMENT = 'style';
const SCRIPT_ELEMENT = 'script';

/// Attribute used to mark a template node and children as literal html to
/// skip processing contents as directives or bindings.
const NG_NON_BINDABLE_ATTR = 'ngNonBindable';
const NG_PROJECT_AS = 'ngProjectAs';
const defaultNgContentSelector = '*';

PreparsedElement preparseElement(HtmlElementAst ast) {
  var selectAttr = defaultNgContentSelector;
  String hrefAttr;
  String relAttr;
  var nonBindable = false;
  String projectAs;

  var attrs = ast.attrs;
  for (int i = 0, len = attrs.length; i < len; i++) {
    var attr = attrs[i];
    var lcAttrName = attr.name.toLowerCase();
    if (lcAttrName == NG_CONTENT_SELECT_ATTR) {
      selectAttr = _normalizeNgContentSelect(attr.value);
    } else if (lcAttrName == LINK_STYLE_HREF_ATTR) {
      hrefAttr = attr.value;
    } else if (lcAttrName == LINK_STYLE_REL_ATTR) {
      relAttr = attr.value;
    } else if (attr.name == NG_NON_BINDABLE_ATTR) {
      nonBindable = true;
    } else if (attr.name == NG_PROJECT_AS) {
      if (attr.value.isNotEmpty) {
        projectAs = attr.value;
      }
    }
  }

  var nodeName = ast.name.toLowerCase();
  var type = _PreparsedElementType.OTHER;
  if (splitNsName(nodeName)[1] == NG_CONTENT_ELEMENT) {
    type = _PreparsedElementType.NG_CONTENT;
  } else if (nodeName == STYLE_ELEMENT) {
    type = _PreparsedElementType.STYLE;
  } else if (nodeName == SCRIPT_ELEMENT) {
    type = _PreparsedElementType.SCRIPT;
  } else if (nodeName == LINK_ELEMENT && relAttr == LINK_STYLE_REL_VALUE) {
    type = _PreparsedElementType.STYLESHEET;
  }
  return new PreparsedElement(
      type, selectAttr, hrefAttr, nonBindable, projectAs);
}

enum _PreparsedElementType { NG_CONTENT, STYLE, STYLESHEET, SCRIPT, OTHER }

class PreparsedElement {
  final _PreparsedElementType type;
  final String selectAttr;
  final String hrefAttr;
  // Bindings or interpolations inside are ignored if nonBindable attribute
  // is specified on an element.
  final bool nonBindable;
  final String projectAs;
  PreparsedElement(this.type, this.selectAttr, this.hrefAttr, this.nonBindable,
      this.projectAs);

  bool get isNgContent => type == _PreparsedElementType.NG_CONTENT;
  bool get isStyle => type == _PreparsedElementType.STYLE;
  bool get isStyleSheet => type == _PreparsedElementType.STYLESHEET;
  bool get isScript => type == _PreparsedElementType.SCRIPT;
  bool get isOther => type == _PreparsedElementType.OTHER;
}

String _normalizeNgContentSelect(String selectAttr) {
  if (selectAttr == null || selectAttr.isEmpty) {
    return defaultNgContentSelector;
  }
  return selectAttr;
}
