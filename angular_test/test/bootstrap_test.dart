// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/src/bootstrap.dart';

import 'bootstrap_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  Injector _noopInjector([Injector i]) => new Injector.empty(i);

  test('should create a new component in the DOM', () async {
    final host = new Element.div();
    final test = await bootstrapForTest(
      ng_generated.NewComponentInDomNgFactory,
      host,
      _noopInjector,
    );
    expect(host.text, contains('Hello World'));
    test.destroy();
  });

  test('should call a handler before initial load', () async {
    final host = new Element.div();
    final test = await bootstrapForTest<BeforeChangeDetection>(
      ng_generated.BeforeChangeDetectionNgFactory,
      host,
      _noopInjector,
      beforeChangeDetection: (comp) => comp.users.add('Mati'),
    );
    expect(host.text, contains('Hello Mati!'));
    test.destroy();
  });

  test('should include user-specified providers', () async {
    final host = new Element.div();
    final test = await bootstrapForTest(
      ng_generated.AddProvidersNgFactory,
      host,
      ([i]) => new Injector.map({TestService: new TestService()}, i),
    );
    AddProviders instance = test.instance;
    expect(instance._testService, isNotNull);
    test.destroy();
  });

  test('should throw if the root component is OnPush', () async {
    expect(
      bootstrapForTest(
        ng_generated.OnPushComponentNgFactory,
        new DivElement(),
        _noopInjector,
      ),
      throwsUnsupportedError,
    );
  }, skip: 'See https://github.com/dart-lang/angular2/issues/329');
}

@Component(
  selector: 'test',
  template: 'Hello World',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NewComponentInDom {}

@Component(
  selector: 'test',
  template: 'Hello {{users.first}}!',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class BeforeChangeDetection {
  // This will fail with an NPE if not initialized before change detection.
  final users = <String>[];
}

@Component(
  selector: 'test',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OnPushComponent {}

@Component(
  selector: 'test',
  template: '',
  changeDetection: ChangeDetectionStrategy.Stateful,
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class XXXComponent extends ComponentState {}
