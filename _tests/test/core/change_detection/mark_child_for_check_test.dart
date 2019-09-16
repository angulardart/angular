@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'mark_child_for_check_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('markChildForCheck() should update', () {
    test('content child', () async {
      final testBed = NgTestBed.forComponent(ng.TestContentChildNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, isEmpty);
      await testFixture.update((component) => component.child.update('a'));
      expect(testFixture.text, 'a');
    });

    test('content children', () async {
      final testBed = NgTestBed.forComponent(ng.TestContentChildrenNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, isEmpty);
      await testFixture.update((component) => component.child.update('a'));
      expect(testFixture.text, 'aaa');
    });

    test('view child', () async {
      final testBed = NgTestBed.forComponent(ng.TestViewChildNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, isEmpty);
      await testFixture.update((component) => component.update('a'));
      expect(testFixture.text, 'a');
    });

    test('view children', () async {
      final testBed = NgTestBed.forComponent(ng.TestViewChildrenNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.text, isEmpty);
      await testFixture.update((component) => component.update('a'));
      expect(testFixture.text, 'aaa');
    });

    // This is a common pattern we should be certain works.
    group('existing provider', () {
      test('content children', () async {
        final testBed = NgTestBed.forComponent(
            ng.TestExistingProviderContentChildrenNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.text, isEmpty);
        await testFixture.update((component) => component.child.update('a'));
        expect(testFixture.text, 'aaa');
      });

      test('view children', () async {
        final testBed = NgTestBed.forComponent(
            ng.TestExistingProviderViewChildrenNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.text, isEmpty);
        await testFixture.update((component) => component.update('a'));
        expect(testFixture.text, 'aaa');
      });
    });

    group('nested', () {
      test('content children', () async {
        final testBed =
            NgTestBed.forComponent(ng.TestEmbeddedContentChildrenNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.text, isEmpty);
        await testFixture.update((component) => component.child.update('a'));
        expect(testFixture.text, 'a');
        await testFixture.update((component) {
          component.isSecondChildVisible = true;
        });
        expect(testFixture.text, 'aa');
        await testFixture.update((component) => component.child.update('b'));
        expect(testFixture.text, 'bb');
        await testFixture.update((component) {
          component.areRemainingChildrenVisible = true;
        });
        expect(testFixture.text, 'bbbb');
      });

      test('view children', () async {
        final testBed =
            NgTestBed.forComponent(ng.TestEmbeddedViewChildrenNgFactory);
        final testFixture = await testBed.create();
        expect(testFixture.text, isEmpty);
        await testFixture.update((component) {
          component.areRemainingChildrenVisible = true;
        });
        expect(testFixture.text, isEmpty);
        await testFixture.update((component) => component.update('a'));
        expect(testFixture.text, 'aaa');
        await testFixture.update((component) {
          component.isSecondChildVisible = true;
        });
        expect(testFixture.text, 'aaaa');
        await testFixture.update((component) => component.update('b'));
        expect(testFixture.text, 'bbbb');
      });
    });
  });
}

@Component(
  selector: 'child',
  template: '{{value}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class Child {
  var value = '';
}

@Component(
  selector: 'has-content-child',
  template: '<ng-content></ng-content>',
)
class HasContentChild {
  HasContentChild(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  @ContentChild(Child)
  Child child;

  void update(String value) {
    child.value = value;
    _changeDetectorRef.markChildForCheck(child);
  }
}

@Component(
  selector: 'test',
  template: '''
    <has-content-child>
      <child></child>
    </has-content-child>
  ''',
  directives: [Child, HasContentChild],
)
class TestContentChild {
  @ViewChild(HasContentChild)
  HasContentChild child;
}

@Component(
  selector: 'has-content-children',
  template: '<ng-content></ng-content>',
)
class HasContentChildren {
  HasContentChildren(this._changeDetectorRef, this._ngZone);

  final ChangeDetectorRef _changeDetectorRef;
  final NgZone _ngZone;

  List<Child> _children = [];
  var _value = '';

  @ContentChildren(Child)
  set children(List<Child> value) {
    _children = value;
    _ngZone.runAfterChangesObserved(() => update(_value));
  }

  void update(String value) {
    _value = value;
    for (final child in _children) {
      child.value = value;
      _changeDetectorRef.markChildForCheck(child);
    }
  }
}

@Component(
  selector: 'test',
  template: '''
    <has-content-children>
      <child></child>
      <child></child>
      <child></child>
    </has-content-children>
  ''',
  directives: [Child, HasContentChildren],
)
class TestContentChildren {
  @ViewChild(HasContentChildren)
  HasContentChildren child;
}

@Component(
  selector: 'test',
  template: '<child></child>',
  directives: [Child],
)
class TestViewChild {
  TestViewChild(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  @ViewChild(Child)
  Child child;

  void update(String value) {
    child.value = value;
    _changeDetectorRef.markChildForCheck(child);
  }
}

@Component(
  selector: 'test',
  template: '''
    <child></child>
    <child></child>
    <child></child>
  ''',
  directives: [Child],
)
class TestViewChildren {
  TestViewChildren(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  @ViewChildren(Child)
  List<Child> children;

  void update(String value) {
    for (final child in children) {
      child.value = value;
      _changeDetectorRef.markChildForCheck(child);
    }
  }
}

abstract class HasValue {
  String value;
}

@Component(
  selector: 'child',
  template: '{{value}}',
  providers: [
    ExistingProvider(HasValue, ChildWithExistingProvider),
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ChildWithExistingProvider implements HasValue {
  var value = '';
}

@Component(
  selector: 'has-content-children',
  template: '<ng-content></ng-content>',
)
class HasExistingProviderContentChildren {
  HasExistingProviderContentChildren(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  @ContentChildren(HasValue)
  List<HasValue> children;

  void update(String value) {
    for (final child in children) {
      child.value = value;
      _changeDetectorRef.markChildForCheck(child);
    }
  }
}

@Component(
  selector: 'test',
  template: '''
    <has-content-children>
      <child></child>
      <child></child>
      <child></child>
    </has-content-children>
  ''',
  directives: [ChildWithExistingProvider, HasExistingProviderContentChildren],
)
class TestExistingProviderContentChildren {
  @ViewChild(HasExistingProviderContentChildren)
  HasExistingProviderContentChildren child;
}

@Component(
  selector: 'test',
  template: '''
    <child></child>
    <child></child>
    <child></child>
  ''',
  directives: [ChildWithExistingProvider],
)
class TestExistingProviderViewChildren {
  TestExistingProviderViewChildren(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  @ViewChildren(HasValue)
  List<HasValue> children;

  void update(String value) {
    for (final child in children) {
      child.value = value;
      _changeDetectorRef.markChildForCheck(child);
    }
  }
}

@Component(
  selector: 'test',
  template: '''
    <has-content-children>
      <child></child>
      <child *ngIf="isSecondChildVisible"></child>
      <ng-container *ngIf="areRemainingChildrenVisible">
        <child></child>
        <child *ngIf="areRemainingChildrenVisible"></child>
      </ng-container>
    </has-content-children>
  ''',
  directives: [Child, HasContentChildren, NgIf],
)
class TestEmbeddedContentChildren {
  var isSecondChildVisible = false;
  var areRemainingChildrenVisible = false;

  @ViewChild(HasContentChildren)
  HasContentChildren child;
}

@Component(
  selector: 'test',
  template: '''
    <child></child>
    <child *ngIf="isSecondChildVisible"></child>
    <ng-container *ngIf="areRemainingChildrenVisible">
      <child></child>
      <child *ngIf="areRemainingChildrenVisible"></child>
    </ng-container>
  ''',
  directives: [Child, NgIf],
)
class TestEmbeddedViewChildren {
  TestEmbeddedViewChildren(this._changeDetectorRef, this._ngZone);

  final ChangeDetectorRef _changeDetectorRef;
  final NgZone _ngZone;

  var isSecondChildVisible = false;
  var areRemainingChildrenVisible = false;

  List<Child> _children = [];
  var _value = '';

  @ViewChildren(Child)
  set children(List<Child> value) {
    _children = value;
    _ngZone.runAfterChangesObserved(() => update(_value));
  }

  void update(String value) {
    _value = value;
    for (final child in _children) {
      child.value = value;
      _changeDetectorRef.markChildForCheck(child);
    }
  }
}
