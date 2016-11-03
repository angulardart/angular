import 'package:angular2/angular2.dart';

@Directive(selector: 'directive')
class TestDirective {}

@Component(selector: 'test-bar', template: '<div>Bar</div>')
class TestSubComponent {}
