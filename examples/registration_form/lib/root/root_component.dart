import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:examples.registration_form/address/address_component.dart';

@Component(
    selector: 'hello-world',
    templateUrl: 'root_component.html',
    directives: [
      formDirectives,
      materialInputDirectives,
      MaterialYesNoButtonsComponent,
      MaterialSaveCancelButtonsDirective,
      NgIf,
      AddressComponent
    ],
    providers: [
      popupBindings,
    ])
class RootComponent {
  @ViewChild('myForm')
  ControlContainer myForm;

  String firstName;
  String lastName;

  Person person;

  void onSubmit() {
    person = _createPerson();
  }

  // TODO(alorenzen): Reset form inputs.
  void onClear() {
    person = null;
  }

  Person _createPerson() {
    return new Person(
      firstName: _controls['first-name'].value,
      lastName: _controls['last-name'].value,
      address: _createAddress(),
    );
  }

  Address _createAddress() {
    return new Address(
      address1: _addressControls['address1'].value,
      address2: _addressControls['address2'].value,
      city: _addressControls['city'].value,
      state: _addressControls['state'].value,
      zip: _addressControls['zip'].value,
    );
  }

  Map<String, AbstractControl> get _controls => myForm.control.controls;
  Map<String, AbstractControl> get _addressControls =>
      (_controls['address'] as ControlGroup).controls;
}

class Person {
  final String firstName;
  final String lastName;
  final Address address;

  Person({this.firstName, this.lastName, this.address});
}

class Address {
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zip;

  Address({this.address1, this.address2, this.city, this.state, this.zip});
}
