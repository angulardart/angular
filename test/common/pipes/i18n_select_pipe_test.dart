@TestOn('browser')
library angular2.test.common.pipes.i18n_select_pipe_test;

import 'package:angular2/common.dart' show I18nSelectPipe;
import 'package:angular2/src/compiler/pipe_resolver.dart' show PipeResolver;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

main() {
  group('I18nSelectPipe', () {
    var pipe;
    var mapping = {
      'male': 'Invite him.',
      'female': 'Invite her.',
      'other': 'Invite them.'
    };
    setUp(() {
      pipe = new I18nSelectPipe();
    });
    test('should be marked as pure', () async {
      inject([], () {
        expect(new PipeResolver().resolve(I18nSelectPipe).pure, true);
      });
    });
    group('transform', () {
      test('should return male text if value is male', () {
        var val = pipe.transform('male', mapping);
        expect(val, 'Invite him.');
      });
      test('should return female text if value is female', () {
        var val = pipe.transform('female', mapping);
        expect(val, 'Invite her.');
      });
      test(
          'should return other text if value is anything other than male or '
          'female', () {
        var val = pipe.transform('Anything else', mapping);
        expect(val, 'Invite them.');
      });
      test('should use \'other\' if value is undefined', () {
        var gender;
        var val = pipe.transform(gender, mapping);
        expect(val, 'Invite them.');
      });
      test('should not support bad arguments', () {
        expect(() => pipe.transform('male', 'hey'), throws);
      });
    });
  });
}
