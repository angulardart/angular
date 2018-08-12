@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1540_reset_deferred_query_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('@deferred should work properly with queries', () async {
    final fixture = await NgTestBed.forComponent(
      ng.ViewChildTestNgFactory,
    ).create();
    expect(fixture.assertOnlyInstance.child, isNull);
    await fixture.update((c) => c.showChild = true);
    expect(fixture.assertOnlyInstance.child, isNotNull);
    await fixture.update((c) => c.showChild = false);
    expect(fixture.assertOnlyInstance.child, isNull);
  });
}

@Component(
  selector: 'view-child-test',
  directives: [
    HelloWorldComponent,
    NgIf,
  ],
  template: r'''
    <template [ngIf]="showChild">
      <hello-world @deferred></hello-world>
    </template>
  ''',
)
class ViewChildTest {
  @ViewChild(HelloWorldComponent)
  HelloWorldComponent child;

  bool showChild = false;
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
