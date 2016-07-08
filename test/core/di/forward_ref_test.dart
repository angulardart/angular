library angular2.test.core.di.forward_ref_test;

import "package:angular2/src/core/di.dart";
import 'package:test/test.dart';

main() {
  group("forwardRef", () {
    test("should wrap and unwrap the reference", () {
      var ref = String;
      expect(ref is Type, isTrue);
      expect(resolveForwardRef(ref), String);
    });
  });
}
