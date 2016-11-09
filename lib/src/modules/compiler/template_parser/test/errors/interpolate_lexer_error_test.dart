import 'package:angular2_template_parser/src/lexer.dart';
import 'package:test/test.dart';

void expectFailure(NgTemplateLexer lexer, String message) {
  var caught = false;
  try {
    lexer.tokenize();
  } on FormatException catch (e) {
    caught = true;
    expect(e.message, message);
  } finally {
    if (!caught) {
      fail('Did not throw FormatException');
    }
  }
}

void main() {
  test('should fail when interpolation never is closed at beginning', () {
    expectFailure(
      new NgTemplateLexer('{{name'),
      'Expected interpolation to end "}}" before EOF',
    );
  });

  test('should fail when interpolation never is closed later on', () {
    expectFailure(
      new NgTemplateLexer('Hello {{name'),
      'Expected interpolation to end "}}" before EOF',
    );
  });
}
