@TestOn('browser')

import 'package:angular2/angular2.dart';
import 'package:angular2/src/core/linker/focus_service.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  tearDown(disposeAnyRunningTest);

  test('Component should register and unregister handlers', () async {
    final testBed = new NgTestBed<FocusableComponent>();
    expect(focusService.blurHandlers, isEmpty);
    expect(focusService.focusHandlers, isEmpty);

    // Should register handlers on component creation.
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect(focusService.blurHandlers, hasLength(1));
    expect(focusService.blurHandlers, contains(testFixture.rootElement));
    expect(focusService.focusHandlers, hasLength(2));
    expect(focusService.focusHandlers, contains(testFixture.rootElement));
    expect(focusService.focusHandlers, contains(div));

    // Should unregister handlers on component destruction.
    await testFixture.dispose();
    expect(focusService.blurHandlers, isEmpty);
    expect(focusService.focusHandlers, isEmpty);
  });

  test('Embedded components should register and unregister handlers', () async {
    final testBed = new NgTestBed<EmbeddedFocusableComponent>();

    // Shouldn't register handlers on host creation.
    final testFixture = await testBed.create();
    expect(focusService.blurHandlers, isEmpty);
    expect(focusService.focusHandlers, isEmpty);

    // Should register handlers on template creation.
    await testFixture.update((component) => component.visible = true);
    final focusable = testFixture.rootElement.querySelector('focusable');
    final div = focusable.querySelector('div');
    expect(focusService.blurHandlers, hasLength(1));
    expect(focusService.blurHandlers, contains(focusable));
    expect(focusService.focusHandlers, hasLength(2));
    expect(focusService.focusHandlers, contains(focusable));
    expect(focusService.focusHandlers, contains(div));

    // Should unregister handlers on template destruction.
    await testFixture.update((component) => component.visible = false);
    expect(focusService.blurHandlers, isEmpty);
    expect(focusService.focusHandlers, isEmpty);
  });
}

@Component(
  selector: 'embedded-focusable',
  template: '<focusable *ngIf=visible></focusable>',
  directives: const [
    FocusableComponent,
    NgIf,
  ],
)
class EmbeddedFocusableComponent {
  bool visible = false;
}

@Component(
  selector: 'focusable',
  host: const {
    '(blur)': r'onBlur()',
    '(focus)': r'onFocus()',
  },
  template: '<focusable-div></focusable-div>',
  directives: const [FocusableDivComponent],
)
class FocusableComponent {
  void onBlur() {}
  void onFocus() {}
}

@Component(
  selector: 'focusable-div',
  template: '<div (focus)="onDivFocus()"></div>',
)
class FocusableDivComponent {
  void onDivFocus() {}
}
