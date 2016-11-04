import 'package:angular2_template_parser/template_parser.dart';
import 'package:test/test.dart';

void main() {
  group('$NgElement', () {
    test('should equal an identical element', () {
      expect(
        new NgElement.unknown('button'),
        new NgElement.unknown('button'),
      );
    });

    test('should equal an identical set of nodes', () {
      expect(
        new NgElement.unknown(
          'button',
          childNodes: [
            new NgElement.unknown('span'),
          ],
        ),
        new NgElement.unknown(
          'button',
          childNodes: [
            new NgElement.unknown('span'),
          ],
        ),
      );
    });
  });

  group('$NgText', () {
    test('should equal an identical text node', () {
      expect(new NgText('Hello'), new NgText('Hello'));
    });

    test('should not equal a non-identical text node', () {
      expect(new NgText('Hello'), isNot(new NgText('World')));
    });
  });
}
