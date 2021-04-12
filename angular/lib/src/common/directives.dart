import 'directives/ng_class.dart' show NgClass;
import 'directives/ng_for.dart' show NgFor;
import 'directives/ng_if.dart' show NgIf;
import 'directives/ng_style.dart' show NgStyle;
import 'directives/ng_switch.dart' show NgSwitch, NgSwitchWhen, NgSwitchDefault;
import 'directives/ng_template_outlet.dart' show NgTemplateOutlet;

export 'directives/ng_class.dart' show NgClass;
export 'directives/ng_for.dart' show NgFor;
export 'directives/ng_if.dart' show NgIf;
export 'directives/ng_style.dart' show NgStyle;
export 'directives/ng_switch.dart' show NgSwitch, NgSwitchWhen, NgSwitchDefault;
export 'directives/ng_template_outlet.dart' show NgTemplateOutlet;

/// A collection of Angular core directives, such as [NgFor] and [NgIf].
///
/// This collection is primarily provided for legacy/compatibility, and it is
/// preferred to instead define exactly what directives you need/use in your
/// `directives: [ ... ]` list instead.
const coreDirectives = [
  NgClass,
  NgFor,
  NgIf,
  NgTemplateOutlet,
  NgStyle,
  NgSwitch,
  NgSwitchWhen,
  NgSwitchDefault,
];
