import 'package:test/test.dart';
import 'package:angular2_template_parser/src/utils.dart';
import 'package:analyzer/analyzer.dart';

void main() {
  group('The Dart analyzer', () {
    test('can be used to parse expressions', () {
      expect(parseAngularExpression('1 + 1', 'template'),
          new isInstanceOf<Expression>());
    });

    test('will yield errors on bad inputs', () {
      expect(() => parseAngularExpression('1 + ', 'template'), throws);
    });
  });
}
