import 'package:angular2/src/compiler/offline_compiler.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';

class TemplateCompilerOutputs {
  final SourceModule templatesSource;
  final NgDepsModel ngDepsModel;

  TemplateCompilerOutputs(this.templatesSource, this.ngDepsModel);
}
