// ignore_for_file: deprecated_member_use
import 'dart:html';
import 'package:angular/angular.dart';

@Component(
  selector: 'queries',
  directives: [
    AnotherDirective,
    NgIf,
  ],
  template: r'''
    <ng-content></ng-content>
    <another #q1></another>
    <another #q2></another>
    <another #q3 *ngIf="someValue"></another>
  ''',
)
class QueriesComponent {
  bool someValue = false;

  @ContentChildren(AnotherDirective)
  List<AnotherDirective> contentChildrenFromField;

  @ContentChild(AnotherDirective)
  AnotherDirective contentChildFromField;

  @ViewChildren('q2')
  List<AnotherDirective> viewChildrenFromField;

  @ViewChild('q2')
  AnotherDirective viewChildFromField;

  @ViewChild('q2', read: ElementRef)
  ElementRef readDIFromElementRef;

  @ViewChild('q2', read: Element)
  Element readDIFromElement;

  @ViewChild('q2', read: HtmlElement)
  HtmlElement readDIFromHtmlElement;

  @ViewChildren(AnotherDirective)
  List<AnotherDirective> usingTypeFromField;

  @ViewChild('q3')
  AnotherDirective nestedViewChild;
}

@Component(
  selector: 'test',
  directives: [
    AnotherDirective,
  ],
  template: r'''
    <another></another>
    <template>
      <another></another>
    </template>
    <template>
      <another></another>
    </template>
  ''',
)
class EmbeddedQueries {
  @ViewChildren(AnotherDirective)
  List viewChildren;
}

@Component(
  selector: 'test',
  directives: [
    AnotherDirective,
  ],
  template: r'''
    <another></another>
    <template>
      <another></another>
    </template>
    <template>
      <another></another>
    </template>
  ''',
)
class EmbeddedQueriesList {
  @ViewChildren(AnotherDirective)
  List<AnotherDirective> viewChildren;
}

@Directive(
  selector: 'another',
)
class AnotherDirective {}

// This closely mimics a piece of internal code that previously crashed.
@Component(
  selector: 'test',
  directives: [
    AnotherDirective,
    NgFor,
    NgIf,
  ],
  template: r'''
    <div *ngIf="conditionA">
      <div *ngIf="conditionB">
        <div *ngFor="let item of items" #taggedItem>
          <another></another>
        </div>
      </div>
    </div>
  ''',
)
class NestedNgForQueriesList {
  final items = [1, 2, 3];
  var conditionA = true;
  var conditionB = true;

  @ViewChildren('taggedItem')
  List<AnotherDirective> taggedItems;
}
