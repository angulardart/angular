@Skip('Test broken by package refactoring. See issue #466')
@TestOn('!browser')
import 'package:analyzer/dart/element/element.dart';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'analyzer_util.dart';
import 'public_apis.dart';

main() {
  Map<String, LibraryElement> elements;

  setUpAll(() async {
    elements = await getLibraries();
    expect(elements, isNotEmpty);
  });

  test('public libraries', () async {
    var publicLibs = elements.keys.where((libPath) {
      var segments = p.split(libPath);

      if (segments.length > 1 && segments.first == 'src') {
        return false;
      }
      return true;
    });

    expect(publicLibs, unorderedEquals(publicLibraries.keys));
  });

  group('library', () {
    for (var lib in publicLibraries.keys) {
      test(lib, () {
        var libElement = elements[lib];
        expect(libElement, isNotNull);

        var expectedElements = publicLibraries[lib];

        if (expectedElements == null) {
          return;
        }

        var members = getMembers(libElement)
          // The reflection based setup doesn't include setters – removing them
          ..removeWhere((s) => s.endsWith('='));

        expect(members, unorderedEquals(expectedElements));
      });
    }
  });
}
