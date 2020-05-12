@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import '233_unicode_template_test.template.dart' as ng;

// Source: https://github.com/dart-lang/angular/issues/233.
void main() {
  test('should be able to compile templates with unicode', () async {
    final testBed = NgTestBed.forComponent(ng.createAppFactory());
    final fixture = await testBed.create();
    expect(
      fixture.text,
      allOf([
        contains('🎂'),
        contains('ΓΔ'),
        contains('↔↕'),
      ]),
    );
  });
}

@Component(
  selector: 'app',
  template: '''
    <div>🎂</div>         <!-- Misc symbols: causes compilation error -->
    <div>ΓΔ</div>         <!-- Greek: OK-->
    <div>↔↕</div>         <!-- Arrows: OK-->
  ''',
)
class App {}
