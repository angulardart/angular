@TestOn('browser')
library angular2.test.compiler.directive_resolver_test;

import 'package:angular2/src/compiler/directive_resolver.dart'
    show DirectiveResolver;
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/facade/lang.dart' show stringify;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

@Directive(selector: 'someDirective')
class SomeDirective {}

@Directive(selector: 'someChildDirective')
class SomeChildDirective extends SomeDirective {}

@Directive(selector: 'someDirective', inputs: const ['c'])
class SomeDirectiveWithInputs {
  @Input()
  var a;
  @Input('renamed')
  var b;
  var c;
}

@Directive(selector: 'someDirective', outputs: const ['c'])
class SomeDirectiveWithOutputs {
  @Output()
  var a;
  @Output('renamed')
  var b;
  var c;
}

@Directive(selector: 'someDirective', outputs: const ['a'])
class SomeDirectiveWithDuplicateOutputs {
  @Output()
  var a;
}

@Directive(selector: 'someDirective', properties: const ['a'])
class SomeDirectiveWithProperties {}

@Directive(selector: 'someDirective', events: const ['a'])
class SomeDirectiveWithEvents {}

@Directive(selector: 'someDirective')
class SomeDirectiveWithSetterProps {
  @Input('renamed')
  set a(value) {}
}

@Directive(selector: 'someDirective')
class SomeDirectiveWithGetterOutputs {
  @Output('renamed')
  get a {
    return null;
  }
}

@Directive(selector: 'someDirective', host: const {'[c]': 'c'})
class SomeDirectiveWithHostBindings {
  @HostBinding()
  var a;
  @HostBinding('renamed')
  var b;
  var c;
}

@Directive(selector: 'someDirective', host: const {'(c)': 'onC()'})
class SomeDirectiveWithHostListeners {
  @HostListener('a')
  onA() {}
  @HostListener('b', const ['\$event.value'])
  onB(value) {}
}

@Directive(
    selector: 'someDirective',
    queries: const {'cs': const ContentChildren('c')})
class SomeDirectiveWithContentChildren {
  @ContentChildren('a')
  dynamic as;
  var c;
}

@Directive(
    selector: 'someDirective', queries: const {'cs': const ViewChildren('c')})
class SomeDirectiveWithViewChildren {
  @ViewChildren('a')
  dynamic as;
  var c;
}

@Directive(
    selector: 'someDirective', queries: const {'c': const ContentChild('c')})
class SomeDirectiveWithContentChild {
  @ContentChild('a')
  dynamic a;
  var c;
}

@Directive(
    selector: 'someDirective', queries: const {'c': const ViewChild('c')})
class SomeDirectiveWithViewChild {
  @ViewChild('a')
  dynamic a;
  var c;
}

class SomeDirectiveWithoutMetadata {}

main() {
  group('DirectiveResolver', () {
    DirectiveResolver resolver;
    setUp(() async {
      resolver = new DirectiveResolver();
      await inject([], () {});
    });
    test('should read out the Directive metadata', () {
      DirectiveMetadata directiveMetadata = resolver.resolve(SomeDirective);
      expect(directiveMetadata.selector, 'someDirective');
    });
    test('should throw if not matching metadata is found', () {
      expect(() {
        resolver.resolve(SomeDirectiveWithoutMetadata);
      },
          throwsWith('No Directive annotation found on '
              '${ stringify ( SomeDirectiveWithoutMetadata )}'));
    });
    test('should not read parent class Directive metadata', () {
      var directiveMetadata = resolver.resolve(SomeChildDirective);
      expect(directiveMetadata.selector, 'someChildDirective');
    });
    group('inputs', () {
      test('should append directive inputs', () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithInputs);
        expect(directiveMetadata.inputs, ['c', 'a', 'b: renamed']);
      });
      test('should work with getters and setters', () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithSetterProps);
        expect(directiveMetadata.inputs, ['a: renamed']);
      });
    });
    group('outputs', () {
      test("should append directive outputs", () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithOutputs);
        expect(directiveMetadata.outputs, ["c", "a", "b: renamed"]);
      });
      test("should work with getters and setters", () {
        var directiveMetadata =
            resolver.resolve(SomeDirectiveWithGetterOutputs);
        expect(directiveMetadata.outputs, ["a: renamed"]);
      });
      test("should throw if duplicate outputs", () {
        expect(() {
          resolver.resolve(SomeDirectiveWithDuplicateOutputs);
        }, throwsWith('Output event \'a\' defined multiple times'));
      });
    });
    group("host", () {
      test("should append host bindings", () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithHostBindings);
        expect(
            directiveMetadata.host, {"[c]": "c", "[a]": "a", "[renamed]": "b"});
      });
      test("should append host listeners", () {
        var directiveMetadata =
            resolver.resolve(SomeDirectiveWithHostListeners);
        expect(directiveMetadata.host,
            {"(c)": "onC()", "(a)": "onA()", "(b)": "onB(\$event.value)"});
      });
    });
    group("queries", () {
      test("should append ContentChildren", () {
        var directiveMetadata =
            resolver.resolve(SomeDirectiveWithContentChildren);
        expect(directiveMetadata.queries['cs'].selector, 'c');
        expect(directiveMetadata.queries['as'].selector, 'a');
      });
      test("should append ViewChildren", () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithViewChildren);
        expect(directiveMetadata.queries['cs'].selector, 'c');
        expect(directiveMetadata.queries['as'].selector, 'a');
      });
      test("should append ContentChild", () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithContentChild);
        expect(directiveMetadata.queries['c'].selector, 'c');
        expect(directiveMetadata.queries['a'].selector, 'a');
      });
      test("should append ViewChild", () {
        var directiveMetadata = resolver.resolve(SomeDirectiveWithViewChild);
        expect(directiveMetadata.queries['c'].selector, 'c');
        expect(directiveMetadata.queries['a'].selector, 'a');
      });
    });
  });
}
