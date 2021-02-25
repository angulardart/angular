import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:angular_ast/angular_ast.dart';

void main() {
  var parse = const NgParser().parse;
  var templatesDir = p.join('test', 'e2e', 'templates');

  // Just assert that we can parse all of these templates without failing.
  Directory(templatesDir).listSync().forEach((file) {
    if (file is File) {
      test('should parse ${p.basenameWithoutExtension(file.path)}', () {
        parse(file.readAsStringSync(), sourceUrl: file.absolute.path);
      });
    }
  });
}
