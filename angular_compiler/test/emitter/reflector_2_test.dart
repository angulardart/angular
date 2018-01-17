import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should support a no-op', () {
    final output = new ReflectableOutput();
    final emitter = new ReflectableEmitter.useCodeBuilder(output);
    expect(emitter.emitImports(), isEmpty);
    expect(emitter.emitInitReflector(), isEmpty);
  });
}
