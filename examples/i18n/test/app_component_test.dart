@TestOn('browser')
import 'package:angular_test/angular_test.dart';
import 'package:examples.i18n/app_component.template.dart' as app_template;
import 'package:examples.i18n/messages/messages_all.dart';
import 'package:intl/intl_browser.dart';
import 'package:test/test.dart';

void main() {
  test('application should render', () async {
    final locale = await findSystemLocale();
    await initializeMessages(locale);
    final testBed = NgTestBed.forComponent(app_template.AppComponentNgFactory);
    expect(testBed.create(), completes);
  });
}
