import 'package:angular/src/compiler/source_module.dart';
import 'package:angular_compiler/angular_compiler.dart';

class TemplateCompilerOutputs {
  final SourceModule templatesSource;
  final ReflectableOutput reflectableOutput;

  TemplateCompilerOutputs(this.templatesSource, this.reflectableOutput);
}
