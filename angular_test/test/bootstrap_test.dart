// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['codegen'])
@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/src/bootstrap.dart';

@AngularEntrypoint()
void main() {
  test('should create a new component in the DOM', () async {
    final host = new Element.div();
    final test = await bootstrapForTest(
      NewComponentInDom,
      host,
    );
    expect(host.text, contains('Hello World'));
    test.destroy();
  });

  test('should call a handler before initial load', () async {
    final host = new Element.div();
    final test = await bootstrapForTest/*<BeforeChangeDetection>*/(
      BeforeChangeDetection,
      host,
      beforeChangeDetection: (comp) => comp.users.add('Mati'),
    );
    expect(host.text, contains('Hello Mati!'));
    test.destroy();
  });

  test('should include user-specified providers', () async {
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
  });

  test('should throw if the root component is OnPush', () async {
    expect(
      bootstrapForTest(OnPushComponent, new DivElement()),
      throwsUnsupportedError,
    );
  }, skip: 'See https://github.com/dart-lang/angular2/issues/329');
}

@Component(
  selector: 'test',
  template: 'Hello World',
)
class NewComponentInDom {}

@Component(
  selector: 'test',
  template: 'Hello {{users.first}}!',
)
class BeforeChangeDetection {
  // This will fail with an NPE if not initialized before change detection.
  final users = <String>[];
}

@Component(
  selector: 'test',
  template: '',
)
class AddProviders {
  final TestService _testService;

  AddProviders(this._testService);
}

@Injectable()
class TestService {}

@Component(
  selector: 'test',
  template: '{{"Hello World"}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class OnPushComponent {}

@Component(
  selector: 'test',
  template: '',
  changeDetection: ChangeDetectionStrategy.Stateful,
)
class XXXComponent extends ComponentState {}
