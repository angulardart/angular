// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:angular_ast/angular_ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

main() {
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
