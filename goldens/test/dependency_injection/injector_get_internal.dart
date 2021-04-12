@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'injector_get_internal.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

/// Shows a complex `injectorGetInternal()` implementation.
void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    MaterialAutoSuggestInputComponent,
    MaterialIcon,
    MaterialInputComponent,
    MaterialInputValueAccessor,
    NgControlName,
    NgControlGroup,
    NgForm,
    RequiredValidator,
  ],
  template: '''
    <form>
      <material-input ngControl="name" required>
        <material-icon trailing></material-icon>
      </material-input>
      <div ngControlGroup="address">
        <material-input ngControl="address1" required></material-input>
        <material-input ngControl="address2"></material-input>
        <material-input ngControl="city" required></material-input>
        <material-auto-suggest-input ngControl="state" required>
        </material-auto-suggest-input>
        <material-input ngControl="zip"></material-input>
      </div>
    </form>
  ''',
)
class GoldenComponent {
  GoldenComponent(Injector i) {
    deopt(i.get);
  }
}

abstract class ControlContainer {}

@Directive(
  selector: 'form',
  providers: [
    ExistingProvider(ControlContainer, NgForm),
  ],
  visibility: Visibility.all,
)
class NgForm implements ControlContainer {}

abstract class NgControl {}

@Directive(
  selector: '[ngControl]',
  providers: [
    ExistingProvider(NgControl, NgControlName),
  ],
)
class NgControlName implements NgControl {}

@Directive(
  selector: '[ngControlGroup]',
  providers: [
    ExistingProvider(ControlContainer, NgControlGroup),
  ],
)
class NgControlGroup implements ControlContainer {}

abstract class Validator {}

const ngValidators = MultiToken<Validator>();

class DeferredValidator implements Validator {}

@Directive(
  selector: '[required][ngControl]',
  providers: [
    ExistingProvider.forToken(ngValidators, RequiredValidator),
  ],
)
class RequiredValidator implements Validator {}

abstract class HasRenderer {}

abstract class SelectionContainer {}

@Component(
  selector: 'material-auto-suggest-input',
  providers: [
    ExistingProvider(HasDisabled, MaterialAutoSuggestInputComponent),
    ExistingProvider(HasRenderer, MaterialAutoSuggestInputComponent),
    ExistingProvider(SelectionContainer, MaterialAutoSuggestInputComponent),
    ExistingProvider(Focusable, MaterialAutoSuggestInputComponent),
  ],
  visibility: Visibility.all,
  template: '',
)
class MaterialAutoSuggestInputComponent {}

@Component(
  selector: 'material-icon',
  template: '',
)
class MaterialIcon {}

abstract class MaterialInputBase {}

abstract class Focusable {}

abstract class HasDisabled {}

abstract class ReferenceDirective {}

@Directive(
  selector: 'material-input',
  visibility: Visibility.all,
)
class MaterialInputValueAccessor {}

abstract class Service {}

class ServiceA implements Service {}

class ServiceB implements Service {}

const luckyNumber = OpaqueToken<int>('luckyNumber');

@Component(
  selector: 'material-input',
  providers: [
    ClassProvider(Service, useClass: ServiceA),
    ClassProvider(DeferredValidator),
    ExistingProvider.forToken(ngValidators, DeferredValidator),
    ExistingProvider(MaterialInputBase, MaterialInputComponent),
    ExistingProvider(Focusable, MaterialInputComponent),
    ExistingProvider(HasDisabled, MaterialInputComponent),
  ],
  viewProviders: [
    ClassProvider(Service, useClass: ServiceB),
    ValueProvider.forToken(luckyNumber, 12),
    ExistingProvider(ReferenceDirective, MaterialInputComponent),
  ],
  template: r'''
    <ng-content select="[trailing]"></ng-content>
  ''',
)
class MaterialInputComponent extends MaterialInputBase
    implements Focusable, HasDisabled, ReferenceDirective {}
