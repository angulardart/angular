// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should refuse to compile late final fields marked @Input()', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'example-comp',
        template: '',
      )
      class ExampleComp {
        @Input()
        late final String name;
      }
    """, errors: [
      allOf(
        contains('Inputs cannot be "late final"'),
      )
    ]);
  });

  test('should refuse to compile non-nullable single child query', () async {
    await compilesExpecting("""
      import 'dart:html';
      import '$ngImport';

      @Component(
        selector: 'example-comp',
        template: '<div></div>',
      )
      class ExampleComp {
        @ViewChild('div')
        set div(Element div) {}
      }
    """, errors: [
      allOf(
        contains('queries must be nullable'),
      )
    ]);
  });

  test('should refuse to compile late fields with a child query', () async {
    await compilesExpecting("""
      import 'dart:html';
      import '$ngImport';

      @Component(
        selector: 'example-comp',
        template: '<div></div>',
      )
      class ExampleComp {
        @ViewChild('div')
        late Element? div;
      }
    """, errors: [
      allOf(
        contains('View and content queries cannot be "late"'),
      )
    ]);
  });

  test('should refuse to compile late fields with a children query', () async {
    await compilesExpecting("""
      import 'dart:html';
      import '$ngImport';

      @Component(
        selector: 'example-comp',
        template: '<div></div>',
      )
      class ExampleComp {
        @ViewChildren('div')
        late List<Element> div;
      }
    """, errors: [
      allOf(
        contains('View and content queries cannot be "late"'),
      )
    ]);
  });

  test('should compile non-nullable fields with a children query', () async {
    await compilesNormally("""
      import 'dart:html';
      import '$ngImport';

      @Component(
        selector: 'example-comp',
        template: '<div></div>',
      )
      class ExampleComp {
        @ViewChildren('div')
        set divs(List<Element> divs) {}
      }
    """);
  });
}
