import 'package:angular2/src/compiler/html_parser.dart' show HtmlParser;
import 'package:angular2/src/compiler/template_preparser.dart'
    show preparseElement, PreparsedElementType, PreparsedElement;
import 'package:test/test.dart';

void main() {
  group("preparseElement", () {
    HtmlParser htmlParser;
    setUp(() async {
      htmlParser = new HtmlParser();
    });

    PreparsedElement preparse(String html) {
      return preparseElement(htmlParser.parse(html, "TestComp").rootNodes[0]);
    }

    test("should detect script elements", () async {
      expect(preparse("<script>").type, PreparsedElementType.SCRIPT);
    });
    test("should detect style elements", () async {
      expect(preparse("<style>").type, PreparsedElementType.STYLE);
    });
    test("should detect stylesheet elements", () async {
      expect(preparse("<link rel=\"stylesheet\">").type,
          PreparsedElementType.STYLESHEET);
      expect(preparse("<link rel=\"stylesheet\" href=\"someUrl\">").hrefAttr,
          "someUrl");
      expect(
          preparse("<link rel=\"someRel\">").type, PreparsedElementType.OTHER);
    });
    test("should detect ng-content elements", () async {
      expect(preparse("<ng-content>").type, PreparsedElementType.NG_CONTENT);
    });
    test("should normalize ng-content.select attribute", () async {
      expect(preparse("<ng-content>").selectAttr, "*");
      expect(preparse("<ng-content select>").selectAttr, "*");
      expect(preparse("<ng-content select=\"*\">").selectAttr, "*");
    });
    test("should extract ngProjectAs value", () {
      expect(preparse("<p ngProjectAs=\"el[attr].class\"></p>").projectAs,
          "el[attr].class");
    });
  });
}
