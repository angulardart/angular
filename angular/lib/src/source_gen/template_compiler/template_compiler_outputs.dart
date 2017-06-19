import 'package:angular/src/compiler/source_module.dart';
import 'package:angular/src/source_gen/common/ng_deps_model.dart';

class TemplateCompilerOutputs {
  final SourceModule templatesSource;
  final NgDepsModel ngDepsModel;

  TemplateCompilerOutputs(this.templatesSource, this.ngDepsModel);
}
