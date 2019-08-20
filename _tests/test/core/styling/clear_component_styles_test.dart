@TestOn('browser')
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'clear_component_styles_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  // Note that `NgTestFixture.dipose()` invokes `debugClearComponentStyles()`.
  group('debugClearComponentStyles()', () {
    test('should clear component styles from DOM', () async {
      await expectTextFontStyle(ng.ItalicTextComponentNgFactory, 'italic');
      await expectTextFontStyle(ng.NormalTextComponentNgFactory, 'normal');
    });
    test('should allow reloading the same component styles', () async {
      await expectTextFontStyle(ng.ItalicTextComponentNgFactory, 'italic');
      await expectTextFontStyle(ng.ItalicTextComponentNgFactory, 'italic');
    });
  });
}

/// Loads [ComponentFactory] and expects its text to have [fontStyle].
Future<void> expectTextFontStyle(
  ComponentFactory<void> componentFactory,
  String fontStyle,
) async {
  final testBed = NgTestBed.forComponent(componentFactory);
  final testFixture = await testBed.create();
  final text = testFixture.rootElement.querySelector('.text');
  expect(text.getComputedStyle().getPropertyValue('font-style'), fontStyle);
  return testFixture.dispose();
}

@Component(
  selector: 'test',
  template: '<p class="text"></p>',
  styles: [
    // Intentionally unscoped to leak between test fixtures if not cleared.
    '''
      ::ng-deep .text {
        font-style: italic;
      }
    ''',
  ],
)
class ItalicTextComponent {}

@Component(
  selector: 'test',
  template: '<p class="text"></p>',
)
class NormalTextComponent {}
