library angular2.test.core.wtf_impl_test;

import 'package:angular2/src/core/profile/wtf_impl.dart' as impl;
import 'package:test/test.dart';

void main() {
  group('Web Tracing Framework', () {
    group('getArgSize', () {
      test("should parse args", () {
        expect(impl.getArgSize('foo#bar'), 0);
        expect(impl.getArgSize('foo#bar()'), 0);
        expect(impl.getArgSize('foo#bar(foo bar)'), 1);
        expect(impl.getArgSize('foo#bar(foo bar, baz q)'), 2);
      });
    });
  });
}
