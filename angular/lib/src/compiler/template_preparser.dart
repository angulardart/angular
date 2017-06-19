import "html_ast.dart" show HtmlElementAst;
import "html_tags.dart" show splitNsName;

const NG_CONTENT_SELECT_ATTR = "select";
const NG_CONTENT_ELEMENT = "ng-content";
const LINK_ELEMENT = "link";
const LINK_STYLE_REL_ATTR = "rel";
const LINK_STYLE_HREF_ATTR = "href";
const LINK_STYLE_REL_VALUE = "stylesheet";
const STYLE_ELEMENT = "style";
const SCRIPT_ELEMENT = "script";
const NG_NON_BINDABLE_ATTR = "ngNonBindable";
const NG_PROJECT_AS = "ngProjectAs";

PreparsedElement preparseElement(HtmlElementAst ast) {
  var selectAttr;
  var hrefAttr;
  var relAttr;
  var nonBindable = false;
  String projectAs;
  ast.attrs.forEach((attr) {
    var lcAttrName = attr.name.toLowerCase();
    if (lcAttrName == NG_CONTENT_SELECT_ATTR) {
      selectAttr = attr.value;
    } else if (lcAttrName == LINK_STYLE_HREF_ATTR) {
      hrefAttr = attr.value;
    } else if (lcAttrName == LINK_STYLE_REL_ATTR) {
      relAttr = attr.value;
    } else if (attr.name == NG_NON_BINDABLE_ATTR) {
      nonBindable = true;
    } else if (attr.name == NG_PROJECT_AS) {
      if (attr.value.length > 0) {
        projectAs = attr.value;
      }
    }
  });
  selectAttr = normalizeNgContentSelect(selectAttr);
  var nodeName = ast.name.toLowerCase();
  var type = PreparsedElementType.OTHER;
  if (splitNsName(nodeName)[1] == NG_CONTENT_ELEMENT) {
    type = PreparsedElementType.NG_CONTENT;
  } else if (nodeName == STYLE_ELEMENT) {
    type = PreparsedElementType.STYLE;
  } else if (nodeName == SCRIPT_ELEMENT) {
    type = PreparsedElementType.SCRIPT;
  } else if (nodeName == LINK_ELEMENT && relAttr == LINK_STYLE_REL_VALUE) {
    type = PreparsedElementType.STYLESHEET;
  }
  return new PreparsedElement(
      type, selectAttr, hrefAttr, nonBindable, projectAs);
}

enum PreparsedElementType { NG_CONTENT, STYLE, STYLESHEET, SCRIPT, OTHER }

class PreparsedElement {
  PreparsedElementType type;
  String selectAttr;
  String hrefAttr;
  // Bindings or interpolations inside are ignored if nonBindable attribute
  // is specified on an element.
  bool nonBindable;
  String projectAs;
  PreparsedElement(this.type, this.selectAttr, this.hrefAttr, this.nonBindable,
      this.projectAs);
}

String normalizeNgContentSelect(String selectAttr) {
  if (selectAttr == null || selectAttr.isEmpty) {
    return "*";
  }
  return selectAttr;
}
