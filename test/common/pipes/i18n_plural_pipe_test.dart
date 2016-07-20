@TestOn('browser')
library angular2.test.common.pipes.i18n_plural_pipe_test;

import "package:angular2/common.dart" show I18nPluralPipe;
import "package:angular2/src/compiler/pipe_resolver.dart" show PipeResolver;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("I18nPluralPipe", () {
    var pipe;
    var mapping = {
      "=0": "No messages.",
      "=1": "One message.",
      "other": "There are some messages."
    };
    var interpolatedMapping = {
      "=0": "No messages.",
      "=1": "One message.",
      "other": "There are # messages, that is #."
    };
    setUp(() {
      pipe = new I18nPluralPipe();
    });
    test("should be marked as pure", () async {
      return inject([], () {
        expect(new PipeResolver().resolve(I18nPluralPipe).pure, true);
      });
    });
    group("transform", () {
      test("should return 0 text if value is 0", () {
        var val = pipe.transform(0, mapping);
        expect(val, "No messages.");
      });
      test("should return 1 text if value is 1", () {
        var val = pipe.transform(1, mapping);
        expect(val, "One message.");
      });
      test("should return other text if value is anything other than 0 or 1",
          () {
        var val = pipe.transform(6, mapping);
        expect(val, "There are some messages.");
      });
      test("should interpolate the value into the text where indicated", () {
        var val = pipe.transform(6, interpolatedMapping);
        expect(val, "There are 6 messages, that is 6.");
      });
      test("should use 'other' if value is undefined", () {
        var messageLength;
        var val = pipe.transform(messageLength, interpolatedMapping);
        expect(val, "There are  messages, that is .");
      });
      test("should not support bad arguments", () {
        expect(() => pipe.transform(0, "hey"), throws);
      });
    });
  });
}
