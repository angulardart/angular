import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/source_module.dart';

/// Elements of a `.template.dart` file to be written to disk.
class TemplateCompilerOutputs {
  /// For each `@GenerateInjector`, how to generate those injectors.
  final List<InjectorReader> injectorsOutput;

  /// For each `@Component`, how to generate the backing views.
  final DartSourceOutput? templateSource;

  /// For each `@Component` and `@Injectable`, how to allow dynamic loading.
  ///
  /// This is known as the `initReflector()` method in `.template.dart` files.
  final ReflectableOutput reflectableOutput;

  const TemplateCompilerOutputs(
    this.templateSource,
    this.reflectableOutput,
    this.injectorsOutput,
  );
}
