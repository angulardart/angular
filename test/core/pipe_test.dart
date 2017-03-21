import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  test('should support pipes with optional paramters', () async {
    final fixture = await new NgTestBed<Example>().create();
    expect(fixture.text, contains('Unpiped: 2014-04-29 06:04:00.000'));
    expect(fixture.text, contains('Piped: Apr 29, 2014'));
  });
}

@Component(
  selector: 'example',
  template: r'''
    Unpiped: {{now}}
    Piped: {{now | date}}
  ''',
  pipes: const [
    DatePipe,
  ],
)
class Example {
  // April 29, 2014, 6:04am.
  final now = new DateTime(2014, DateTime.APRIL, 29, 6, 4);
}
