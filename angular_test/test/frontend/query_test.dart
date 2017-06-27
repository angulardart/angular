// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['aot'])
@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

@AngularEntrypoint()
void main() {
  tearDown(disposeAnyRunningTest);

  test('should support querying for a component', () async {
    final fixture = await new NgTestBed<SingleComponentTest>().create();
    await fixture.query(
      (el) => el.componentInstance is ChildComponent,
      (child) {
        expect(child, const isInstanceOf<ChildComponent>());
      },
    );
  });

  test('should return null for no matching component', () async {
    final fixture = await new NgTestBed<SingleComponentTest>().create();
    await fixture.query(
      (el) => el.componentInstance is SingleComponentTest,
      (child) {
        expect(child, isNull);
      },
    );
  });

  test('should support querying for many components', () async {
    final fixture = await new NgTestBed<ManyComponentTest>().create();
    await fixture.queryAll(
      (el) => el.componentInstance is ChildComponent,
      (children) {
        expect(children, hasLength(3));
      },
    );
  });
}

@Component(
  selector: 'child',
  template: '',
)
class ChildComponent {}

@Component(
  selector: 'single',
  directives: const [ChildComponent],
  template: '<child></child>',
)
class SingleComponentTest {}

@Component(
  selector: 'many',
  directives: const [ChildComponent],
  template: r'''
    <child></child>
    <child></child>
    <child></child>
  ''',
)
class ManyComponentTest {}
