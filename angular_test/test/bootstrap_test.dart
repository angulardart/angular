// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['aot'])
@TestOn('browser')
import 'dart:html';

import 'package:angular_test/src/bootstrap.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

@AngularEntrypoint()
void main() {
  test(
    'should create a new component in the DOM',
    NewComponentInDom._runTest,
  );

  test(
    'should call a handler before initial load',
    BeforeChangeDetection._runTest,
  );

  test(
    'should include user-specified providers',
    AddProviders._runTest,
  );
}

@Component(
  selector: 'test',
  template: 'Hello World',
)
class NewComponentInDom {
  static _runTest() async {
    final host = new Element.div();
    final test = await bootstrapForTest(
      NewComponentInDom,
      host,
    );
    expect(host.text, contains('Hello World'));
    test.destroy();
  }
}

@Component(
  selector: 'test',
  template: 'Hello {{users.first}}!',
)
class BeforeChangeDetection {
  static _runTest() async {
    final host = new Element.div();
    final test = await bootstrapForTest/*<BeforeChangeDetection>*/(
      BeforeChangeDetection,
      host,
      beforeChangeDetection: (comp) => comp.users.add('Mati'),
    );
    expect(host.text, contains('Hello Mati!'));
    test.destroy();
  }

  // This will fail with an NPE if not initialized before change detection.
  final users = <String>[];
}

@Component(
  selector: 'test',
  template: '',
)
class AddProviders {
  static _runTest() async {
    final host = new Element.div();
    final test = await bootstrapForTest(
      AddProviders,
      host,
      addProviders: const [
        TestService,
      ],
    );
    AddProviders instance = test.instance;
    expect(instance._testService, isNotNull);
    test.destroy();
  }

  final TestService _testService;

  AddProviders(this._testService);
}

@Injectable()
class TestService {}
