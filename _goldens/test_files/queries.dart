import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'queries',
  directives: const [AnotherDirective],
  template: r'''
    <another #q1></another>
    <another #q2></another>
    <another #q3></another>
    <another #q4></another>
    <another #q5></another>
    <another #q6></another>
    <another #q7></another>
    <another #q8></another>
  ''',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class QueriesComponent {
  @ContentChildren('q5')
  QueryList<AnotherDirective> contentChildrenFromField;

  @ViewChildren('q6')
  QueryList<AnotherDirective> viewChildrenFromField;

  @ContentChild('q7')
  AnotherDirective contentChildFromField;

  @ViewChild('q8')
  AnotherDirective viewChildFromField;

  @ViewChild('q8', read: ElementRef)
  ElementRef readDIFromElementRef;

  @ViewChild('q8', read: Element)
  ElementRef readDIFromElement;

  @ViewChild('q8', read: HtmlElement)
  ElementRef readDIFromHtmlElement;

  @ViewChildren(AnotherDirective)
  QueryList<AnotherDirective> usingTypeFromField;
}

@Directive(selector: 'another')
class AnotherDirective {}
