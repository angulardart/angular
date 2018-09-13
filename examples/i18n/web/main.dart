import 'package:angular/angular.dart';
import 'package:examples.i18n/app_component.template.dart' as app_template;
import 'package:examples.i18n/messages/messages_all.dart';
import 'package:intl/intl_browser.dart';

void main() async {
  final locale = await findSystemLocale();
  await initializeMessages(locale);
  runApp(app_template.AppComponentNgFactory);
}
