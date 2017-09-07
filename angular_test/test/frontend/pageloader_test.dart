// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['codegen'])
@TestOn('browser')
import 'package:pageloader/objects.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

@AngularEntrypoint()
void main() {
  tearDown(disposeAnyRunningTest);

  test('should support page objects and page loader', () async {
    final fixture = await new NgTestBed<TestComponent>().create();
    final pageObject = await fixture.resolvePageObject<ClickCounterPO>(
      ClickCounterPO,
    );
    expect(await pageObject.button.visibleText, 'Click count: 0');
    await pageObject.button.click();
    expect(await pageObject.button.visibleText, 'Click count: 1');
  });
}

@Component(
  selector: 'test',
  directives: const [
    ClickCounterComponent,
  ],
  template: r'''
    <counter></counter>
  ''',
)
class TestComponent {}

@Component(
  selector: 'counter',
  template: r'''
    <button (click)="onClick()">Click count: {{count}}</button>
  ''',
)
class ClickCounterComponent {
  var count = 0;

  void onClick() {
    count++;
  }
}

@EnsureTag('counter')
class ClickCounterPO {
  @ByTagName('button')
  PageLoaderElement button;
}
