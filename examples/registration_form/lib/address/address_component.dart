import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_input/material_auto_suggest_input.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

@Component(
  selector: 'address-cmp',
  templateUrl: 'address_component.html',
  exports: [states, isPristine],
  directives: [
    formDirectives,
    materialInputDirectives,
    MaterialAutoSuggestInputComponent,
    RequiredState
  ],
)
class AddressComponent {}

bool isPristine(NgControl control) => control.pristine;

@Directive(
    selector: 'material-auto-suggest-input[ngControl="state"]',
    providers: [ExistingProvider.forToken(NG_VALIDATORS, RequiredState)])
class RequiredState implements Validator {
  @override
  Map<String, dynamic> validate(AbstractControl control) =>
      states.contains(control.value)
          ? null
          : {'state': 'Please select a state from the list'};
}

const List<String> states = <String>[
  'Alabama',
  'Alaska',
  'Arizona',
  'Arkansas',
  'California',
  'Colorado',
  'Connecticut',
  'Delaware',
  'Florida',
  'Georgia',
  'Hawaii',
  'Idaho',
  'Illinois',
  'Indiana',
  'Iowa',
  'Kansas',
  'Kentucky',
  'Louisiana',
  'Maine',
  'Maryland',
  'Massachusetts',
  'Michigan',
  'Minnesota',
  'Mississippi',
  'Missouri',
  'Montana',
  'Nebraska',
  'Nevada',
  'New Hampshire',
  'New Jersey',
  'New Mexico',
  'New York',
  'North Carolina',
  'North Dakota',
  'Ohio',
  'Oklahoma',
  'Oregon',
  'Pennsylvania',
  'Rhode Island',
  'South Carolina',
  'South Dakota',
  'Tennessee',
  'Texas',
  'Utah',
  'Vermont',
  'Virginia',
  'Washington',
  'West Virginia',
  'Wisconsin',
  'Wyoming',
];
