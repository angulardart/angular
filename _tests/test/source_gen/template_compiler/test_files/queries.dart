import 'package:angular/angular.dart';

@Component(
  selector: 'queries',
  queries: const {
    'queryFromAnnotation': const Query('q1'),
    'viewQueryFromAnnotation': const ViewQuery('q2'),
    'contentChildrenFromAnnotation': const ContentChildren('q3'),
    'viewChildrenFromAnnotation': const ViewChildren('q4'),
    'contentChildFromAnnotation': const ContentChild('q5'),
    'viewChildFromAnnotation': const ViewChild('q6'),
  },
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
    <another #q9></another>
    <another #q10></another>
    <another #q11></another>
    <another #q12></another>
  ''',
)
class QueriesComponent {
  QueryList<AnotherDirective> queryFromAnnotation;
  QueryList<AnotherDirective> viewQueryFromAnnotation;
  QueryList<AnotherDirective> contentChildrenFromAnnotation;
  QueryList<AnotherDirective> viewChildrenFromAnnotation;
  AnotherDirective contentChildFromAnnotation;
  AnotherDirective viewChildFromAnnotation;

  @Query('q7')
  QueryList<AnotherDirective> queryFromField;

  @ViewQuery('q8')
  QueryList<AnotherDirective> viewQueryFromField;

  @ContentChildren('q9')
  QueryList<AnotherDirective> contentChildrenFromField;

  @ViewChildren('q10')
  QueryList<AnotherDirective> viewChildrenFromField;

  @ContentChild('q11')
  AnotherDirective contentChildFromField;

  @ViewChild('q12')
  AnotherDirective viewChildFromField;

  @ViewChild('q12', read: ElementRef)
  ElementRef readDIFromElement;

  @ViewChildren(AnotherDirective)
  QueryList<AnotherDirective> usingTypeFromField;
}

@Directive(selector: 'another')
class AnotherDirective {}
