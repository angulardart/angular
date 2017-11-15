// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(const ['codegen'])
@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'bed_lifecycle_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  Element docRoot;
  Element testRoot;

  setUp(() {
    docRoot = new Element.tag('doc-root');
    testRoot = new Element.tag('ng-test-bed-example-test');
    docRoot.append(testRoot);
  });

  tearDown(disposeAnyRunningTest);

  test('should render, update, and destroy a component', () async {
    // We are going to verify that the document root has a new node created (our
    // component), the node is updated (after change detection), and after
    // destroying the test the document root has been cleared.
    final testBed = new NgTestBed<AngularLifecycle>(host: testRoot);
    final fixture = await testBed.create();
    expect(docRoot.text, isEmpty);
    await fixture.update((c) => c.value = 'New value');
    expect(docRoot.text, 'New value');
    await fixture.dispose();
    print(docRoot.innerHtml);
    expect(docRoot.text, isEmpty);
  });

  test('should invoke ngOnChanges, then ngOnInit', () async {
    final fixture = await new NgTestBed<NgOnChangesInitOrder>().create(
      beforeChangeDetection: (root) => root.name = 'Hello',
    );
    await fixture.query<ChildWithLifeCycles>(
      (el) => el.componentInstance is ChildWithLifeCycles,
      (child) {
        expect(child.events, ['OnChanges:name=Hello', 'OnInit']);
      },
    );
  });
}

@Component(
  selector: 'test',
  template: '{{value}}',
)
class AngularLifecycle {
  String value = '';
}

@Component(
  selector: 'test',
  directives: const [ChildWithLifeCycles],
  template: '<child [name]="name"></child>',
)
class NgOnChangesInitOrder {
  String name;
}

@Component(
  selector: 'child',
  template: '',
)
class ChildWithLifeCycles implements OnChanges, OnInit {
  final events = <String>[];

  @Input()
  String name = '';

  @override
  void ngOnChanges(_) {
    events.add('OnChanges:name=$name');
  }

  @override
  void ngOnInit() {
    events.add('OnInit');
  }
}
