@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;

void main() {
  group("CompileMetadata", () {
    group("TemplateMetadata", () {
      test("should use ViewEncapsulation.Emulated by default", () {
        expect(CompileTemplateMetadata().encapsulation,
            ViewEncapsulation.Emulated);
      });
    });
    group("Pipe", () {
      test("should be pure by default", () {
        expect(CompilePipeMetadata().pure, true);
      });
    });
  });
}
