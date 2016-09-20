@TestOn('browser')
library angular2.test.common.pipes.number_pipe_test;

import "package:angular2/common.dart"
    show DecimalPipe, PercentPipe, CurrencyPipe;
import 'package:test/test.dart';

void main() {
  group("Number pipes", () {
    group("DecimalPipe", () {
      var pipe;
      setUp(() {
        pipe = new DecimalPipe();
      });
      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(12345), "12,345");
          expect(pipe.transform(123, ".2"), "123.00");
          expect(pipe.transform(1, "3."), "001");
          expect(pipe.transform(1.1, "3.4-5"), "001.1000");
          expect(pipe.transform(1.123456, "3.4-5"), "001.12346");
          expect(pipe.transform(1.1234), "1.123");
        });
        test("should not support other objects", () {
          expect(() => pipe.transform(new Object()), throws);
        });
      });
    });
    group("PercentPipe", () {
      var pipe;
      setUp(() {
        pipe = new PercentPipe();
      });
      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(1.23), "123%");
          expect(pipe.transform(1.2, ".2"), "120.00%");
        });
        test("should not support other objects", () {
          expect(() => pipe.transform(new Object()), throws);
        });
      });
    });
    group("CurrencyPipe", () {
      var pipe;
      setUp(() {
        pipe = new CurrencyPipe();
      });
      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(123), "USD123");
          expect(pipe.transform(12, "EUR", false, ".2"), "EUR12.00");
        });
        test("should not support other objects", () {
          expect(() => pipe.transform(new Object()), throws);
        });
      });
    });
  });
}
