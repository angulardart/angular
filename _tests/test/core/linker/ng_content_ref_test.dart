import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_content_ref_test.template.dart' as ng;

void main() {
  group('NgContentRef', () {
    tearDown(() => disposeAnyRunningTest());

    group('hasContent', () {
      group('returns false when there\'s no projected content', () {
        test('with select', () async {
          var testBed = NgTestBed(ng.createItsEmptyFactory());
          var testFixture = await testBed.create();
          var element = testFixture.rootElement;
          var childElement = element.querySelector('has-content-api');
          expect(childElement, hasTextContent('hasContent:false'));
        });

        test('without select', () async {
          var testBed = NgTestBed(ng.createWithoutSelectorAndEmptyFactory());
          var testFixture = await testBed.create();
          var element = testFixture.rootElement;
          var childElement = element.querySelector('no-select-has-content');
          expect(childElement, hasTextContent('hasContent:false'));
        });

        test('Api on Dart', () async {
          var testBed = NgTestBed(ng.createItsEmptyOnDartFactory());
          var testFixture = await testBed.create();
          expect(
              testFixture.assertOnlyInstance.child!.byRef!.hasContent, isFalse);
          expect(testFixture.assertOnlyInstance.child!.byType!.hasContent,
              isFalse);
          expect(
              testFixture.assertOnlyInstance.child!.byTypes!.single.hasContent,
              isFalse);
        });
      });

      group('returns true when there\'s projected content', () {
        test('with select', () async {
          var testBed = NgTestBed(ng.createItHasProjectedContentFactory());
          var testFixture = await testBed.create();
          var element = testFixture.rootElement;
          var childElement = element.querySelector('has-content-api');
          expect(childElement, hasTextContent('hasContent:true'));
        });

        test('without select', () async {
          var testBed =
              NgTestBed(ng.createWithoutSelectorAndHasContentsFactory());
          var testFixture = await testBed.create();
          var element = testFixture.rootElement;
          var childElement = element.querySelector('no-select-has-content');
          expect(childElement, hasTextContent('hasContent:true'));
        });

        test('Api on Dart', () async {
          var testBed =
              NgTestBed(ng.createItHasProjectedContentOnDartFactory());
          var testFixture = await testBed.create();
          expect(
              testFixture.assertOnlyInstance.child!.byRef!.hasContent, isTrue);
          expect(
              testFixture.assertOnlyInstance.child!.byType!.hasContent, isTrue);
          expect(
              testFixture.assertOnlyInstance.child!.byTypes!.single.hasContent,
              isTrue);
        });
      });
    });

    group('ngProjectAs', () {
      test('hasContent is true when there\'s a projected element', () async {
        var testBed = NgTestBed(ng.createHasMatchNgProjectAsFactory());
        var testFixture = await testBed.create();
        var element = testFixture.rootElement;
        var childElement = element.querySelector('has-content-api');
        expect(childElement, hasTextContent('hasContent:true'));
      });
    });

    group('NgIf', () {
      test('hasContent is true when value of *ngIf is true', () async {
        var testBed = NgTestBed(ng.createNgIfComponentFactory());
        var testFixture = await testBed.create();
        var element = testFixture.rootElement;
        var childElement = element.querySelector('no-select-has-content');
        expect(childElement, hasTextContent('hasContent:true'));
      });

      test('hasContent is false when value of *ngIf is false', () async {
        var testBed = NgTestBed(ng.createNgIfComponentFactory());
        var testFixture = await testBed.create();
        await testFixture.update((NgIfComponent component) {
          component.flag = false;
        });
        var element = testFixture.rootElement;
        var childElement = element.querySelector('no-select-has-content');
        expect(childElement, hasTextContent('hasContent:false'));
      });
    });

    group('NgFor', () {
      test('hasContent is false when list of *ngFor is empty', () async {
        var testBed = NgTestBed(ng.createNgForComponentFactory());
        var testFixture = await testBed.create();
        var element = testFixture.rootElement;
        var childElement = element.querySelector('no-select-has-content');
        expect(childElement, hasTextContent('hasContent:false'));
      });

      test('hasContent is true when list of *ngFor has items', () async {
        var testBed = NgTestBed(ng.createNgForComponentFactory());
        var testFixture = await testBed.create();
        await testFixture.update((NgForComponent component) {
          component.items = [1];
        });
        var element = testFixture.rootElement;
        var childElement = element.querySelector('no-select-has-content');
        expect(childElement, hasTextContent('hasContent:true'));
      });
    });

    test('<ng-content> in a template', () async {
      var testBed = NgTestBed(ng.createNgIfInTemplateFactory());
      var testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child!.hasContent, isTrue);
      // set false
      await testFixture
          .update((component) => component.child!.isContentVisible = false);
      expect(testFixture.assertOnlyInstance.child!.ref, isNull);
      // set back to true
      await testFixture
          .update((component) => component.child!.isContentVisible = true);
      expect(testFixture.assertOnlyInstance.child!.hasContent, isTrue);
    });
  });
}

@Component(
  selector: 'its-empty',
  template: '''
    <has-content-api></has-content-api>
  ''',
  directives: [HasContentApiComponent],
)
class ItsEmpty {}

@Component(
  selector: 'it-has-projected-content',
  template: '''
    <has-content-api>
      <div class="foo"></div>
    </has-content-api>
  ''',
  directives: [HasContentApiComponent],
)
class ItHasProjectedContent {}

@Component(
  selector: 'has-content-api',
  template: 'hasContent:{{fooRef.hasContent}}'
      '<ng-content select=".foo" #fooRef></ng-content>',
)
class HasContentApiComponent {}

@Component(
  selector: 'no-select-and-empty',
  template: '<no-select-has-content></no-select-has-content>',
  directives: [NoSelectorHasContentComponent],
)
class WithoutSelectorAndEmpty {}

@Component(
  selector: 'no-select-and-has-contents',
  template:
      '<no-select-has-content><div></div><div></div></no-select-has-content>',
  directives: [NoSelectorHasContentComponent],
)
class WithoutSelectorAndHasContents {}

@Component(
  selector: 'no-select-has-content',
  template: 'hasContent:{{ref.hasContent}}<ng-content #ref></ng-content>',
)
class NoSelectorHasContentComponent {}

@Component(
  selector: 'has-match-ng-project-as',
  template: '<ng-project-as><template class="foo"></template></ng-project-as>',
  directives: [NgProjectAsComponent],
)
class HasMatchNgProjectAs {}

@Component(
  selector: 'ng-project-as',
  template:
      '<has-content-api><ng-content select=".foo" ngProjectAs=".foo"></ng-content></has-content-api>',
  directives: [HasContentApiComponent],
)
class NgProjectAsComponent {}

@Component(
  selector: 'ng-if-comp',
  template:
      '<no-select-has-content><div *ngIf="flag"></div></no-select-has-content>',
  directives: [NoSelectorHasContentComponent, NgIf],
)
class NgIfComponent {
  bool flag = true;
}

@Component(
  selector: 'ng-for-comp',
  template:
      '<no-select-has-content><div *ngFor="let item of items"></div></no-select-has-content>',
  directives: [NoSelectorHasContentComponent, NgFor],
)
class NgForComponent {
  List<int> items = [];
}

@Component(
  selector: 'its-empty',
  template: '''
    <api-on-dart></api-on-dart>
  ''',
  directives: [ApiOnDartComponent],
)
class ItsEmptyOnDart {
  @ViewChild(ApiOnDartComponent)
  ApiOnDartComponent? child;
}

@Component(
  selector: 'it-has-projected-content',
  template: '''
    <api-on-dart>
      <div class="foo"></div>
    </api-on-dart>
  ''',
  directives: [ApiOnDartComponent],
)
class ItHasProjectedContentOnDart {
  @ViewChild(ApiOnDartComponent)
  ApiOnDartComponent? child;
}

@Component(
  selector: 'api-on-dart',
  template: '<ng-content select=".foo" #fooRef></ng-content>',
)
class ApiOnDartComponent {
  @ViewChild('fooRef')
  NgContentRef? byRef;

  @ViewChild(NgContentRef)
  NgContentRef? byType;

  @ViewChildren(NgContentRef)
  List<NgContentRef>? byTypes;
}

@Component(
  selector: 'if-in-template',
  template: '<template-comp><span>foo</span></template-comp>',
  directives: [EmbeddedTemplateComp],
)
class NgIfInTemplate {
  @ViewChild(EmbeddedTemplateComp)
  EmbeddedTemplateComp? child;
}

@Component(
  selector: 'template-comp',
  template: '''
    <ng-container *ngIf="isContentVisible">
      <ng-content #content></ng-content>
    </ng-container>
  ''',
  directives: [NgIf],
)
class EmbeddedTemplateComp {
  @ViewChild('content')
  NgContentRef? ref;

  bool isContentVisible = true;

  bool get hasContent => ref?.hasContent ?? false;
}
