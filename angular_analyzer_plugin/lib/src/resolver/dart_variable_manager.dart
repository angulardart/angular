import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';

/// Tracks variables in a [CompilationUnitElement] so analyzer APIs succeed.
///
/// `package:analyzer` has certain expectations around variables that could
/// cause a crash if those expectations are not held. Here we create a shell
/// element structure to hold dart variables that ensures the analyzer
/// resolution APIs succeed for template expressions using local variables
/// (`ngFor` vars, `#`-vars, etc).
class DartVariableManager {
  Template template;
  Source templateSource;
  AnalysisErrorListener errorListener;

  CompilationUnitElementImpl htmlCompilationUnitElement;

  ClassElementImpl htmlClassElement;
  MethodElementImpl htmlMethodElement;
  DartVariableManager(this.template, this.templateSource, this.errorListener);

  LocalVariableElement newLocalVariableElement(
      int offset, String name, DartType type) {
    // ensure artificial Dart elements in the template source
    if (htmlMethodElement == null) {
      htmlCompilationUnitElement = CompilationUnitElementImpl()
        ..source = templateSource;
      htmlClassElement = ClassElementImpl('AngularTemplateClass', -1);
      htmlCompilationUnitElement.types = <ClassElement>[htmlClassElement];
      htmlMethodElement = MethodElementImpl('angularTemplateMethod', -1);
      htmlClassElement.methods = <MethodElement>[htmlMethodElement];
    }
    // add a new local variable
    return LocalVariableElementImpl(name, offset)
      ..type = type
      ..enclosingElement = htmlMethodElement;
  }
}
