import 'package:test/test.dart';
import 'package:angular/src/common/pipes/number_pipe.dart';

void main() {
  group("Number pipes", () {
    group("DecimalPipe", () {
      var pipe = DecimalPipe();

      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(12345), "12,345");
          expect(pipe.transform(123, ".2"), "123.00");
          expect(pipe.transform(1, "3."), "001");
          expect(pipe.transform(1.1, "3.4-5"), "001.1000");
          expect(pipe.transform(1.123456, "3.4-5"), "001.12346");
          expect(pipe.transform(1.1234), "1.123");
        });
      });
    });
    group("PercentPipe", () {
      var pipe = PercentPipe();

      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(1.23), "123%");
          expect(pipe.transform(1.2, ".2"), "120.00%");
        });
      });
    });
    group("CurrencyPipe", () {
      var pipe = CurrencyPipe();
      group("transform", () {
        test("should return correct value for numbers", () {
          expect(pipe.transform(123), "USD123");
          expect(pipe.transform(12, "EUR", false, ".2"), "EUR12.00");
        });
      });
    });
  });
}
