@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should bind events to local variables', () async {
    await compilesExpecting("""
      import '$ngImport';

      @Component(
        selector: 'hero',
        template: '<div *ngFor="let cb of callbacks"><button (click)="cb()">X</button></div>',
        directives: [NgFor]
      )
      class HeroComponent {
        final callbacks = [() => print("Hello"), () => print("Hi")]
      }
    """, errors: [
      allOf(contains('Expected method for event binding'),
          containsSourceLocation(1, 43))
    ]);
  });
}
