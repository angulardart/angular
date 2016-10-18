import 'package:angular2_template_parser/template_parser.dart';
import 'package:source_span/source_span.dart';
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

    test('should equal an identical text node with the same source', () {
      expect(
        new NgText('Hello', null, new SourceSpan(
          new SourceLocation(0),
          new SourceLocation(5),
          'Hello',
        )),
        new NgText('Hello', null, new SourceSpan(
          new SourceLocation(0),
          new SourceLocation(5),
          'Hello',
        )),
      );
    });

    test('should not equal a non-identical text with (difference source)', () {
      expect(
        new NgText('Hello', null, new SourceSpan(
          new SourceLocation(5), 
          new SourceLocation(10),
          'Hello',
        )),
        new NgText('Hello', null, new SourceSpan(
          new SourceLocation(0),
          new SourceLocation(5),
          'Hello',
        )),
      );
    });
  });
}
