@TestOn('browser')
library angular2.test.common.pipes.json_pipe_test;

import 'package:angular2/common.dart' show JsonPipe;
import 'package:angular2/core.dart' show Component;
import 'package:angular2/src/facade/lang.dart' show Json, StringWrapper;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

main() {
  group('JsonPipe', () {
    var regNewLine = '\n';
    var inceptionObj;
    var inceptionObjString;
    var pipe;
    String normalize(String obj) {
      return StringWrapper.replace(obj, regNewLine, '');
    }
    setUp(() {
      inceptionObj = {
        'dream': {
          'dream': {'dream': 'Limbo'}
        }
      };
      inceptionObjString = '{\n'
          '  \"dream\": {\n'
          '    \"dream\": {\n'
          '      \"dream\": \"Limbo\"\n'
          '    }\n'
          '  }\n'
          '}';
      pipe = new JsonPipe();
    });
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
        var dream2 = normalize(Json.stringify(inceptionObj));
        expect(dream1, dream2);
      });
    });
    group('integration', () {
      test('should work with mutable objects', () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb.createAsync(TestComp).then((fixture) {
            List<num> mutable = [1];
            fixture.debugElement.componentInstance.data = mutable;
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent('[\n  1\n]'));
            mutable.add(2);
            fixture.detectChanges();
            expect(fixture.debugElement.nativeElement,
                hasTextContent('[\n  1,\n  2\n]'));
            completer.done();
          });
        });
      });
    });
  });
}

@Component(
    selector: 'test-comp', template: '{{data | json}}', pipes: const [JsonPipe])
class TestComp {
  dynamic data;
}
