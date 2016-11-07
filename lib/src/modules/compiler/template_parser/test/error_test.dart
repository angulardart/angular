import 'package:angular2_template_parser/testing.dart';
import 'package:test/test.dart';

void main() {
  test('should fail when an illegal character is parsed in element tag', () {
    expect(
        getParseError('<div><my-π>Some Text</my-π></div>'),
        'line 1, column 7: Tag name for an Element is invalid\n'
        '<div><my-π>Some Text</my-π></div>\n'
        '      ^^^^\n'
        '\n'
        'To fix this error, make sure the tag name starts with an ascii letter, followed \n'
        'by any number of ascii letters, numbers, or the symbols "-" and "_".');
  });

  test('should fail when multiple structural directives are found', () {
    expect(
        getParseError('<div *ngIf="baz" *ngFor="let foo of bars"></div>'),
        'line 1, column 18: Cannot have more than a single structural (*) directive on an element\n'
        '<div *ngIf="baz" *ngFor="let foo of bars"></div>\n'
        '                 ^^^^^^\n'
        '\n'
        'Structural directives (i.e. *ngFor) are just a convenience syntax:\n'
        '    <template [ngFor]="let foo of bars">\n'
        '      <div>...</div>\n'
        '    </template>\n'
        '\n\n'
        'Rewrite your tags as nested <template> tags in order you want them to apply:\n'
        '    <template [ngIf]="baz">\n'
        '      <template [ngFor]="let foo of bars">\n'
        '        <div>...</div>\n'
        '      </template>\n'
        '    </template>');
  });
}
