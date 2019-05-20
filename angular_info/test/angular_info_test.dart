import 'package:test/test.dart';
import 'package:angular_info/angular_info_generator.dart';

main() {
  group('generator', () {
    Future<String> fileA;
    Future<String> fileB;

    setUp(() {
      fileA = Future.value("""
      ..some code
      // View for component ComponentA (changeDetection: Default)
      .. some more code
      // View for component ComponentAA (changeDetection: OnPush)
      .. even more code.
      """);

      fileB = Future.value("""
      ..some code
      // View for component ComponentB (changeDetection: Default)
      """);
    });
    test('should count components', () async {
      expect(await AngularInfoGenerator([fileA, fileB]).generateTextReport(),
          'Found 3 components');
    });
  });
}
