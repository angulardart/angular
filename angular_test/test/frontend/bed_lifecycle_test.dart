// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    docRoot = Element.tag('doc-root');
    testRoot = Element.tag('ng-test-bed-example-test');
    docRoot.append(testRoot);
  });

  tearDown(disposeAnyRunningTest);

  test('should render, update, and destroy a component', () async {
    // We are going to verify that the document root has a new node created (our
    // component), the node is updated (after change detection), and after
    // destroying the test the document root has been cleared.
    final testBed = NgTestBed<AngularLifecycle>(host: testRoot);
    final fixture = await testBed.create();
    expect(docRoot.text, isEmpty);
    await fixture.update((c) => c.value = 'New value');
    expect(docRoot.text, 'New value');
    await fixture.dispose();
    print(docRoot.innerHtml);
    expect(docRoot.text, isEmpty);
  });

  test('should invoke ngAfterChanges, then ngOnInit', () async {
    final fixture = await NgTestBed<NgAfterChangesInitOrder>().create(
      beforeChangeDetection: (root) => root.name = 'Hello',
    );
    expect(
      fixture.assertOnlyInstance.child.events,
      ['AfterChanges:name=Hello', 'OnInit'],
    );
  });

  test(
      'should invoke ngAfterChanges with asynchronous beforeChangeDetection,'
      ' then ngOnInit', () async {
    final fixture = await NgTestBed<NgAfterChangesInitOrder>().create(
      beforeChangeDetection: (root) async => root.name = 'Hello',
    );
    expect(
      fixture.assertOnlyInstance.child.events,
      ['AfterChanges:name=Hello', 'OnInit'],
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
  directives: [ChildWithLifeCycles],
  template: '<child [name]="name"></child>',
)
class NgAfterChangesInitOrder {
  String name;

  @ViewChild(ChildWithLifeCycles)
  ChildWithLifeCycles child;
}

@Component(
  selector: 'child',
  template: '',
  visibility: Visibility.all,
)
class ChildWithLifeCycles implements AfterChanges, OnInit {
  final events = <String>[];

  @Input()
  String name = '';

  @override
  void ngAfterChanges() {
    events.add('AfterChanges:name=$name');
  }

  @override
  void ngOnInit() {
    events.add('OnInit');
  }
}
