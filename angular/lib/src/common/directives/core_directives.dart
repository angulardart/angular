import 'ng_class.dart' show NgClass;
import 'ng_for.dart' show NgFor;
import 'ng_if.dart' show NgIf;
import 'ng_style.dart' show NgStyle;
import 'ng_switch.dart' show NgSwitch, NgSwitchWhen, NgSwitchDefault;
import 'ng_template_outlet.dart' show NgTemplateOutlet;

@Deprecated('Renamed to "coreDirectives"')
const List<Type> CORE_DIRECTIVES = const [
  NgClass,
  NgFor,
  NgIf,
  NgTemplateOutlet,
  NgStyle,
  NgSwitch,
  NgSwitchWhen,
  NgSwitchDefault,
];
