import 'package:angular/src/compiler/source_module.dart';
import 'package:angular_compiler/angular_compiler.dart';

class TemplateCompilerOutputs {
  final List<InjectorReader> injectorsOutput;
  final SourceModule templatesSource;
  final ReflectableOutput reflectableOutput;

  TemplateCompilerOutputs(
    this.templatesSource,
    this.reflectableOutput,
    this.injectorsOutput,
  );
}
