import 'package:logging/logging.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart';
import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../expression_parser/parser.dart' show Parser;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import 'constants.dart' show EventHandlerVars;
import 'view_name_resolver.dart';

class DirectiveCompileResult {
  final o.ClassStmt _changeDetectorClass;
  DirectiveCompileResult(this._changeDetectorClass);

  List<o.Statement> get statements => [_changeDetectorClass];
}

class DirectiveCompiler {
  final CompileDirectiveMetadata directive;
  final bool genDebugInfo;
  final bool hasOnChangesLifecycle;
  final Parser parser;

  Logger _logger;
  List<o.ClassField> fields;
  final viewMethods = <o.ClassMethod>[];
  int expressionFieldCounter = 0;

  DirectiveCompiler(this.directive, this.parser, this.genDebugInfo)
      : hasOnChangesLifecycle =
            directive.lifecycleHooks.contains(LifecycleHooks.OnChanges);

  DirectiveCompileResult compile() {
    assert(directive.requiresDirectiveChangeDetector);
    var classStmt = _buildChangeDetector();
    return new DirectiveCompileResult(classStmt);
  }

  Logger get logger => _logger ??= new Logger('View Compiler');

  o.ClassStmt _buildChangeDetector() {
    var ctor = _createChangeDetectorConstructor(directive);

    var superClassExpr;
    if (hasOnChangesLifecycle) {
      superClassExpr = o.importExpr(Identifiers.DirectiveChangeDetector);
    }
    var changeDetectorClass = new o.ClassStmt(changeDetectorClassName,
        superClassExpr, fields ?? const [], const [], ctor, viewMethods);
    return changeDetectorClass;
  }

  o.ClassMethod _createChangeDetectorConstructor(
      CompileDirectiveMetadata meta) {
    var instanceType = o.importType(meta.type.identifier);
    addField(new o.ClassField(
      'instance',
      outputType: instanceType,
      modifiers: [
        o.StmtModifier.Final,
      ],
    ));
    var constructorArgs = [new o.FnParam('this.instance', instanceType)];
    var statements;
    if (hasOnChangesLifecycle) {
      statements = [
        new o.WriteClassMemberExpr(
                'directive', new o.ReadClassMemberExpr('instance'))
            .toStmt()
      ];
    } else {
      statements = const [];
    }
    return new o.ClassMethod(null, constructorArgs, statements);
  }

  void addField(o.ClassField field) {
    fields ??= new List<o.ClassField>();
    fields.add(field);
  }

  String get changeDetectorClassName => '${directive.type.name}NgCd';
}

class DirectiveNameResolver extends ViewNameResolver {
  DirectiveNameResolver() : super(null);

  void addLocal(String name, o.Expression e) {
    throw new UnsupportedError('Locals are not supported in directives');
  }

  @override
  o.Expression getLocal(String name) {
    if (name == EventHandlerVars.event.name) {
      return EventHandlerVars.event;
    }
    return null;
  }

  @override
  o.Expression callPipe(
      String name, o.Expression input, List<o.Expression> args) {
    throw new UnsupportedError('Pipes are not support in directives');
  }
}
