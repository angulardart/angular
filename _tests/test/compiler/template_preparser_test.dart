@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular/src/compiler/html_parser.dart' show HtmlParser;
import 'package:angular/src/compiler/template_preparser.dart'
    show preparseElement, PreparsedElement;

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
      expect(preparse("<script>").isScript, true);
    });
    test("should detect style elements", () async {
      expect(preparse("<style>").isStyle, true);
    });
    test("should detect stylesheet elements", () async {
      expect(preparse("<link rel=\"stylesheet\">").isStyleSheet, true);
      expect(preparse("<link rel=\"stylesheet\" href=\"someUrl\">").hrefAttr,
          "someUrl");
      expect(preparse("<link rel=\"someRel\">").isOther, true);
    });
    test("should detect ng-content elements", () async {
      expect(preparse("<ng-content>").isNgContent, true);
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
