@TestOn('browser')
import 'dart:convert';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'json_pipe_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('JsonPipe', () {
    Map inceptionObj;
    String inceptionObjString;
    JsonPipe pipe;

    String normalize(String obj) {
      return obj.replaceFirst('\n', '');
    }

    setUp(() {
      inceptionObj = {
        'dream': {
          'dream': {'dream': 'Limbo'}
        }
      };
      inceptionObjString = '{\n'
          '  "dream": {\n'
          '    "dream": {\n'
          '      "dream": "Limbo"\n'
          '    }\n'
          '  }\n'
          '}';
      pipe = JsonPipe();
    });

    tearDown(() => disposeAnyRunningTest());

    group('transform', () {
      test('should return JSON-formatted string', () {
        expect(pipe.transform(inceptionObj), inceptionObjString);
      });
      test('should return JSON-formatted string even when normalized', () {
        var dream1 = normalize(pipe.transform(inceptionObj));
        var dream2 = normalize(inceptionObjString);
        expect(dream1, dream2);
      });
      test('should return JSON-formatted string similar to Json.stringify', () {
        var dream1 = normalize(pipe.transform(inceptionObj));
        var dream2 =
            normalize(const JsonEncoder.withIndent('  ').convert(inceptionObj));
        expect(dream1, dream2);
      });
    });
    group('integration', () {
      test('should work with mutable objects', () async {
        var testBed = NgTestBed<TestComp>();
        var fixture = await testBed.create();
        List<num> mutable = [1];
        await fixture.update((TestComp component) {
          component.data = mutable;
        });
        expect(fixture.text, contains('[\n  1\n]'));
        mutable.add(2);
        await fixture.update();
        expect(fixture.text, contains('[\n  1,\n  2\n]'));
      });
    });
  });
}

@Component(
  selector: 'test-comp',
  template: '{{data | json}}',
  pipes: [JsonPipe],
)
class TestComp {
  dynamic data;
}
