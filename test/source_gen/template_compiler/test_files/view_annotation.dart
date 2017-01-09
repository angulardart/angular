import 'package:angular2/angular2.dart';

@Component(selector: 'test-foo')
@View(template: '<div *ngIf="true">Foo</div>', directives: const [NgIf])
class TestFooComponent {}
