import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'view_child_regression_test.template.dart' as ng;

void main() {
  test('$ViewChild#nativeElement should be accessible', () async {
    final fixture = await NgTestBed(ng.createViewChildTestFactory()).create();
    await fixture.update((component) {
      expect(component.portalElement, isNull);
      component.showChildHost = true;
    });
    await fixture.update((component) {
      expect(component.portalElement, isNotNull);
      expect(component.containerElement, isNotNull);
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
  directives: [
    ChildHostDirective,
    NgIf,
  ],
)
class ViewChildTest {
  @ViewChild('portal', read: Element)
  Element? portalElement;

  @ViewChild('container', read: Element)
  Element? containerElement;

  @ViewChild('marker', read: ViewContainerRef)
  ViewContainerRef? markerViewContainer;

  var showChildHost = false;
}

@Directive(
  selector: '[childHost]',
)
class ChildHostDirective {}
