import 'package:third_party.dart_src.acx.material_input/material_input.dart';
import 'package:third_party.dart_src.acx.material_input/material_auto_suggest_input.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

@Component(
  selector: 'address-cmp',
  templateUrl: 'address_component.html',
  exports: [states],
  directives: [
    formDirectives,
    materialInputDirectives,
    MaterialAutoSuggestInputComponent,
    RequiredFirstValidator,
    RequiredState
  ],
)
class AddressComponent {}

/// Validator that ensures that [requiredFirst] control has a value before this
/// control.
///
/// For example an address input where given two address lines the second line
/// shouldn't be the only one with a value.
// TODO(alorenzen): Improve the interop between the two Controls. Errors should
// clear when requiredFirst value is set.
@Directive(selector: '[requiredFirst]', providers: const [
  const ExistingProvider.forToken(NG_VALIDATORS, RequiredFirstValidator)
])
class RequiredFirstValidator implements Validator {
  @Input()
  NgControl requiredFirst;

  @override
  Map<String, dynamic> validate(AbstractControl control) {
    if (control.value == null || control.value == '') return null;
    if (requiredFirst.control.value != null &&
        requiredFirst.control.value != '') return null;
    return {'requiredFirst': 'Enter a value for Address 1'};
  }
}

@Directive(
    selector: 'material-auto-suggest-input[ngControl^="state"]',
    providers: const [
      const ExistingProvider.forToken(NG_VALIDATORS, RequiredState)
    ])
class RequiredState implements Validator {
  @override
  Map<String, dynamic> validate(AbstractControl control) =>
      states.contains(control.value)
          ? null
          : {'state': 'Please select a state from the list'};
}

const List<String> states = const <String>[
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
