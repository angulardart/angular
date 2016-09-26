import 'package:test/test.dart';

// A Trivial test to validate that the target platform works
// Allows us to fail fast with broken content-shell, etc
void main() {
  test("trivial test", () {
    expect(true, isTrue);
  });
}
