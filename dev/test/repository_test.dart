@TestOn('vm')
import 'package:dev/repository.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  test('should find all packages', () async {
    await d.dir('angular', [
      d.dir('package_1', [
        d.file('pubspec.yaml', r'''
          name: package_1
        '''),
      ]),
    ]).create();
    final repository = new Repository.fromPath(d.sandbox);
    expect(repository.rootPath, d.sandbox);
  });
}
