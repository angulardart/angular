import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'pipe_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support pipes with optional paramters', () async {
    final fixture = await NgTestBed(ng.createExampleFactory()).create();
    expect(fixture.text, contains('Unpiped: 2014-04-29 06:04:00.000'));
    expect(fixture.text, contains('Piped: Apr 29, 2014'));
  });

  test('should support type arguments on transform return and parameter types',
      () async {
    final testBed = NgTestBed(ng.createNopComponentFactory());
    final testFixture = await testBed.create();
    expect(testFixture.text, '[1, 2, 3]');
  });

  test('pure pipe should only be invoked when its input changes', () async {
    final testBed = NgTestBed(ng.createTestPurePipeComponentFactory());
    final testFixture = await testBed.create();
    // Initial invocation.
    expect(PurePipe.singleton.invocations, equals(1));
    // Shouldn't be invoked again with the same value to transform.
    await testFixture.update();
    expect(PurePipe.singleton.invocations, equals(1));
    // Should be invoked again with the new value to transform.
    await testFixture.update((component) => component.value = '');
    expect(PurePipe.singleton.invocations, equals(2));
  });

  test('should pass a pipe with multiple arguments as argument to function',
      () async {
    final testBed = NgTestBed(ng.createTestOptionalArgumentFactory());
    final testFixture = await testBed.create(
      beforeChangeDetection: (component) {
        component
          ..prefix = '('
          ..suffix = ')'
          ..value = 'Hello';
      },
    );
    expect(testFixture.text, contains('(Hello).'));
    expect(testFixture.text, contains('(Hello)!'));
  });

  test('a missing @Optional() pipe dependency does not throw', () async {
    var testBed = NgTestBed(ng.createTestOptionalAnnotationFactory());
    expect(testBed.create(), completes);
  });
}

@Component(
  selector: 'example',
  template: r'''
    Unpiped:&ngsp;{{now}}
    Piped:&ngsp;{{$pipe.date(now)}}
  ''',
  pipes: [
    DatePipe,
  ],
)
class Example {
  // April 29, 2014, 6:04am.
  final now = DateTime(2014, DateTime.april, 29, 6, 4);
}

@Pipe('nop')
class NopPipe {
  List<int> transform(List<int> values) => values;
}

@Component(
  selector: 'nop',
  template: r'{{$pipe.nop(values)}}',
  pipes: [NopPipe],
)
class NopComponent {
  final values = [1, 2, 3];
}

@Pipe('pure')
class PurePipe {
  static PurePipe singleton = PurePipe._();

  int _invocations = 0;
  int get invocations => _invocations;

  factory PurePipe() => singleton;

  PurePipe._();

  // ignore: prefer_void_to_null
  Null transform(_) {
    _invocations++;
    return null;
  }
}

@Component(
  selector: 'test-pure-pipe',
  template: r'{{$pipe.pure(value)}}',
  pipes: [PurePipe],
)
class TestPurePipeComponent {
  String? value;
}

@Pipe('optionalArgument')
class OptionalArgumentPipe {
  String transform(
    String value,
    String prefix,
    String suffix, [
    String punctuation = '.',
  ]) =>
      '$prefix$value$suffix$punctuation';
}

@Component(
  selector: 'test',
  template: r'''
    {{function($pipe.optionalArgument(value, prefix, suffix))}}
    {{function($pipe.optionalArgument(value, prefix, suffix, "!"))}}
  ''',
  pipes: [OptionalArgumentPipe],
)
class TestOptionalArgument {
  late String prefix;
  late String suffix;
  late String value;

  String function(String value) => value;
}

abstract class TestService {}

@Pipe('test')
class OptionalAnnotationPipe {
  OptionalAnnotationPipe(@Optional() TestService? _);

  dynamic transform(dynamic value) => value;
}

@Component(
  selector: 'test',
  template: r'{{$pipe.test(value)}}',
  pipes: [OptionalAnnotationPipe],
)
class TestOptionalAnnotation {
  var value = 'Hello world!';
}
