import 'package:angular_components/laminate/popup/module.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_yes_no_buttons/material_yes_no_buttons.dart';
import 'package:angular/angular.dart';
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
  ],
)
class RootComponent {
  Person person;

  void onSubmit(NgForm form) {
    person = _createPerson(form.value);
  }

  // TODO(alorenzen): Reset form inputs.
  void onClear(NgForm form) {
    person = null;
    form.control.reset();
  }

  Person _createPerson(Map<String, dynamic> values) {
    return Person(
      firstName: values['first-name'],
      lastName: values['last-name'],
      address: _createAddress(values['address']),
    );
  }

  Address _createAddress(Map<String, dynamic> values) {
    return Address(
      address1: values['address1'],
      address2: values['address2'],
      city: values['city'],
      state: values['state'],
      zip: values['zip'],
    );
  }
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
