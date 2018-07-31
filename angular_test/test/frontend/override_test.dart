// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:async';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'override_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support overriding providers', () async {
    final fixture = await NgTestBed<TestViewComponent>().create();
    expect(fixture.text, 'Hello World');
  });
}

@Component(
  selector: 'view-comp',
  providers: [DataService],
  template: '{{value}}',
)
class ViewComponent implements OnInit {
  final DataService _service;

  String value;

  ViewComponent(this._service);

  @override
  ngOnInit() async => value = await _service.fetch();
}

@Component(
  selector: 'test-view-comp',
  directives: [
    OverrideDirective,
    ViewComponent,
  ],
  template: '<view-comp override></view-comp>',
)
class TestViewComponent {}

@Directive(
  selector: '[override]',
  providers: [
    Provider(DataService, useClass: FakeDataService),
  ],
)
class OverrideDirective {}

@Injectable()
class DataService {
  Future<String> fetch() => throw UnimplementedError();
}

@Injectable()
class FakeDataService implements DataService {
  @override
  Future<String> fetch() async => 'Hello World';
}
