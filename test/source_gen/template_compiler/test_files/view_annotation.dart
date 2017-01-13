import 'package:angular2/angular2.dart';

@Component(selector: 'test-foo', preserveWhitespace: false)
@View(
    template: '<div *ngIf="true">Foo</div>',
    directives: const [NgIf],
    styles: const ['div { font-size: 10px; }'])
class TestFooComponent {}
