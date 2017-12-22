// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'bed_static_test.template.dart' as ng_generated;

void main() {
  // Intentionally does not use ng_generated.initReflector().
  tearDown(disposeAnyRunningTest);

  test('should run a completely static test', () async {
    final testBed = new NgTestBed.withFactory(ng_generated.StaticTestNgFactory);
    final fixture = await testBed.create();
    expect(fixture.text, 'Hello World');
    await fixture.update((comp) => comp.value = 'Angular');
    expect(fixture.text, 'Hello Angular');
  });
}

@Component(
  selector: 'test',
  template: 'Hello {{value}}',
)
class StaticTest {
  var value = 'World';
}
