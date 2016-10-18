import 'package:angular2_template_parser/src/utils.dart';
import 'package:charcode/charcode.dart';
import 'package:test/test.dart';

void main() {
  group('isWhiteSpace', () {
    test('should recognize spaces', () {
      expect(isWhiteSpace(' '.codeUnitAt(0)), isTrue);
    });

    test('should recognize new lines', () {
      expect(isWhiteSpace('\n'.codeUnitAt(0)), isTrue);
    });

    test('should recognize tabs', () {
      expect(isWhiteSpace('\t'.codeUnitAt(0)), isTrue);
    });

    test('should recognize carriage returns', () {
      expect(isWhiteSpace('\r'.codeUnitAt(0)), isTrue);
    });

    test('should recognize not anything else', () {
      expect(new Iterable<int>.generate(255).where(isWhiteSpace), hasLength(4));
    });
  });

  test('isAsciiLetter should recognize a-Z', () {
    for (var c = 0; c < $a; c++) {
      expect(isAsciiLetter(c), isFalse);
    }
    for (var c = $a; c <= $Z; c++) {
      expect(isAsciiLetter(c), isTrue);
    }
    for (var c = $Z + 1; c < 256; c++) {
      expect(isAsciiLetter(c), isFalse);
    }
  });
}
