@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_control_repeated_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  // Regression test for https://github.com/dart-lang/angular2/issues/164.
  test('should update an NgForm without throwing an NPE', () async {
    final testBed = NgTestBed<AppComponent>();
    expect(
      (await testBed.create()).rootElement.innerHtml,
      contains(r'<input title="Input #0:true">'),
    );
  });
}

@Component(
  selector: 'root',
  directives: [
    formDirectives,
    NgFor,
  ],
  template: r'''
    <form>
      <input *ngFor="let val of values; let idx = index"
             [ngModel]="val"
             ngControl="input-{{idx}}"
             title="Input #{{idx}}:{{val}}">
    </form>
  ''',
)
class AppComponent {
  Iterable<String> values;
  bool b = false;

  AppComponent() {
    _update();
    Timer.run(_update);
  }

  void _update() {
    values = List.from([b.toString()]);
    print(values);
    b = !b;
  }
}
