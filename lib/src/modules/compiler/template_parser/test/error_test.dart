import 'package:angular2_template_parser/src/ast.dart';
import 'package:angular2_template_parser/src/parser.dart';
import 'package:angular2_template_parser/src/source_error.dart';
import 'package:test/test.dart';


void main() {
  List<NgAstNode> parse(String text) =>
      new NgTemplateParser(errorHandler: (error) => throw error)
        .parse(text)
        .toList();

  test('should throw when provided an error handler on illegal tag', () {
         expect(
           () => parse('<div><my-π>Some Text</my-π></div>'),
           throwsA(new isInstanceOf<IllegalTagName>()));
       });

  test('should throw when provided an error handler on multiple structural'
       ' directives', () {
         expect(
           () => parse('<div *ngIf="baz" *ngFor="let foo of bars"></div>'),
           throwsA(new isInstanceOf<ExtraStructuralDirective>()));
       });
}
