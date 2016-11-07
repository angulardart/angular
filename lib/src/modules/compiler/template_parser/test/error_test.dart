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

  test('should fail when interpolation nodes have invalid dart expressions',
      () {
    expect(
        getParseError('<div> 1 + 1 = {{1 + }}</div>'),
        'line 1, column 17: Error in interpolation node: Expected an identifier\n'
        '\n'
        '<div> 1 + 1 = {{1 + }}</div>\n'
        '                ^^^^\n'
        '\n'
        '');
  });

  test('should fail when there is more than an identifier in a banana', () {
    expect(getParseErrors('<div [(prop)]="1 +"></div>'), [
      'line 1, column 16: Error in bananan (in a box): Expected an identifier\n'
          '\n'
          '<div [(prop)]="1 +"></div>\n'
          '               ^^^\n'
          '\n'
          ''
    ]);
  });

  test('should fail when an event node contains an invalid expression', () {
    expect(
        getParseError('<div (click)="1 +"></div>'),
        'line 1, column 15: Error in event node: Expected an identifier\n'
        '\n'
        '<div (click)="1 +"></div>\n'
        '              ^^^\n'
        '\n'
        '');
  });

  test('should fail when a property node contains an invalid expression', () {
    expect(
        getParseError('<div [prop]="1 + "></div>'),
        'line 1, column 14: Error in property node: Expected an identifier\n'
        '\n'
        '<div [prop]="1 + "></div>\n'
        '             ^^^^\n'
        '\n'
        '');
  });
}
