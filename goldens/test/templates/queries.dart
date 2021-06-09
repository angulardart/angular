@JS()
library golden;

import 'dart:html';

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'queries.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    AnotherDirective,
    EmbeddedQueries,
    NestedNgForQueriesList,
    StaticSingleQuery,
    DynamicSingleQuery,
    ContentQuery,
    ContentHasReference,
    NgIf,
  ],
  template: r'''
    <ng-content></ng-content>
    <another #q1></another>
    <another #q2></another>
    <another #q3 *ngIf="someValue"></another>

    <embedded-queries></embedded-queries>
    <nested-ng-for-queries></nested-ng-for-queries>
    <static-single-query></static-single-query>
    <dynamic-single-query></dynamic-single-query>
    <content-query></content-query>
    <content-has-reference></content-has-reference>
  ''',
)
class GoldenComponent {
  bool someValue = false;

  @ContentChildren(AnotherDirective)
  set contentChildrenFromField(List<AnotherDirective>? value) {
    deopt(value);
  }

  @ContentChild(AnotherDirective)
  set contentChildFromField(AnotherDirective? value) {
    deopt(value);
  }

  @ViewChildren('q2', read: AnotherDirective)
  set viewChildrenFromField(List<AnotherDirective>? value) {
    deopt(value);
  }

  @ViewChild('q2', read: AnotherDirective)
  set viewChildFromField(AnotherDirective? value) {
    deopt(value);
  }

  @ViewChild('q2', read: ElementRef)
  set readDIFromElementRef(ElementRef? value) {
    deopt(value);
  }

  @ViewChild('q2', read: Element)
  set readDIFromElement(Element? value) {
    deopt(value);
  }

  @ViewChildren(AnotherDirective)
  set usingTypeFromField(List<AnotherDirective>? value) {
    deopt(value);
  }

  @ViewChild('q3', read: AnotherDirective)
  set nestedViewChild(AnotherDirective? value) {
    deopt(value);
  }
}

@Component(
  selector: 'embedded-queries',
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
  set viewChildren(List<AnotherDirective>? value) {
    deopt(value);
  }
}

@Directive(
  selector: 'another',
)
class AnotherDirective {}

// This closely mimics a piece of internal code that previously crashed.
@Component(
  selector: 'nested-ng-for-queries',
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

  @ViewChildren('taggedItem', read: AnotherDirective)
  set taggedItems(List<AnotherDirective>? value) {
    deopt(value);
  }
}

// Demonstrates an optimization used to treat a single value query as static
// when there are dynamic matching results.
@Component(
  selector: 'static-single-query',
  template: '''
    <another></another>
    <another *ngIf="isVisible"></another>
  ''',
  directives: [AnotherDirective, NgIf],
)
class StaticSingleQuery {
  var isVisible = false;

  @ViewChild(AnotherDirective)
  set another(AnotherDirective? value) {
    deopt(value);
  }
}

// Demonstrates an optimization used to prune unnecessary values from a dynamic
// single value query when there are multiple results.
@Component(
  selector: 'dynamic-single-query',
  template: '''
    <ng-container *ngIf="isVisible">
      <another></another>
      <another></another>
    </ng-container>
    <another></another>
    <another></another>
  ''',
  directives: [AnotherDirective, NgIf],
)
class DynamicSingleQuery {
  var isVisible = false;

  @ViewChild(AnotherDirective)
  set another(AnotherDirective? value) {
    deopt(value);
  }
}

// Queries whether <ng-content> has matched element.
@Component(
  selector: 'content-query',
  template: '''
    <div #header>
      <ng-content select="header"></ng-content>
    </div>
  ''',
  directives: [],
)
class ContentQuery {
  @ViewChild('header')
  set header(Element? value) {
    deopt(value);
  }

  @ContentChild(Element)
  set contentHeader(Element? value) {
    deopt(value);
  }
}

// Put reference on <ng-content>.
@Component(
  selector: 'content-has-reference',
  template: '''
    <ng-content #foo></ng-content>
    {{foo.hasContent}}
    {{ref!.hasContent}}
  ''',
)
class ContentHasReference {
  @ViewChild('foo')
  NgContentRef? ref;
}
