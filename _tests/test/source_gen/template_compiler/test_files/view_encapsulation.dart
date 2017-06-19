import 'package:angular/angular.dart';

@Component(
    selector: 'Emulated',
    template: '<div>Emulated</div>',
    encapsulation: ViewEncapsulation.Emulated)
class EmulatedComponent {}

@Component(
    selector: 'Native',
    template: '<div>Native</div>',
    encapsulation: ViewEncapsulation.Native)
class NativeComponent {}

@Component(
    selector: 'None',
    template: '<div>None</div>',
    encapsulation: ViewEncapsulation.None)
class NoneComponent {}
