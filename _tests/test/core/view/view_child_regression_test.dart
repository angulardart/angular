@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'view_child_regression_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  test('$ViewChild#nativeElement should be accessible', () async {
    final fixture = await new NgTestBed<ViewChildTest>().create();
    await fixture.update((component) {
      expect(component.portalElement, isNull);
      component.showChildHost = true;
    });
    await fixture.update((component) {
      expect(component.portalElement.nativeElement, isNotNull);
      expect(component.containerElement.nativeElement, isNotNull);
      expect(component.markerViewContainer, isNotNull);
    });
  });
}

@Component(
  selector: 'view-child-test',
  template: r'''
    <div #container>
      <template [ngIf]="showChildHost">
        <div #portal childHost></div>
      </template>
    </div>
    <div #marker></div>
  ''',
  directives: const [
    ChildHostDirective,
    NgIf,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ViewChildTest {
  @ViewChild('portal')
  ElementRef portalElement;

  @ViewChild('container')
  ElementRef containerElement;

  @ViewChild('marker', read: ViewContainerRef)
  ViewContainerRef markerViewContainer;

  var showChildHost = false;
}

@Directive(
  selector: '[childHost]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ChildHostDirective {}
