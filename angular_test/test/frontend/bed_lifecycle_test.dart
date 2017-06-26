// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['aot'])
@TestOn('browser')
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

@AngularEntrypoint()
void main() {
  Element docRoot;
  Element testRoot;

  setUp(() {
    docRoot = new Element.tag('doc-root');
    testRoot = new Element.tag('ng-test-bed-example-test');
    docRoot.append(testRoot);
  });

  tearDown(disposeAnyRunningTest);

  test('should render, update, and destroy a component', () {
    return AngularLifecycle._runTest(docRoot, testRoot);
  });
}

@Component(selector: 'test', template: '{{value}}')
class AngularLifecycle {
  static _runTest(Element docRoot, Element testRoot) async {
    // We are going to verify that the document root has a new node created (our
    // component), the node is updated (after change detection), and after
    // destroying the test the document root has been cleared.
    final fixture = await new NgTestBed<AngularLifecycle>(
      host: testRoot,
    )
        .create();
    expect(docRoot.text, isEmpty);
    await fixture.update((c) => c.value = 'New value');
    expect(docRoot.text, 'New value');
    await fixture.dispose();
    expect(docRoot.text, isEmpty);
  }

  String value = '';
}
