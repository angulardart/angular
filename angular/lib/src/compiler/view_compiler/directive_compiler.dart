import 'package:source_span/source_span.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectionStrategy, ChangeDetectorState;
import 'package:angular/src/core/metadata/lifecycle_hooks.dart';
import 'package:angular_compiler/cli.dart';

import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../expression_parser/ast.dart' as ast;
import '../identifiers.dart';
import '../output/convert.dart' show typeArgumentsFrom;
import '../output/output_ast.dart' as o;
import '../parse_util.dart' show ParseErrorLevel;
import '../schema/element_schema_registry.dart' show ElementSchemaRegistry;
import '../template_ast.dart' show BoundElementPropertyAst, BoundExpression;
import '../template_parser.dart';
import 'bound_value_converter.dart';
import 'compile_method.dart';
import 'compile_view.dart' show CompileViewStorage;
import 'constants.dart' show DetectChangesVars, EventHandlerVars;
import 'ir/view_storage.dart';
import 'property_binder.dart' show bindAndWriteToRenderer;
import 'view_name_resolver.dart';

class DirectiveCompileResult {
  final o.ClassStmt _changeDetectorClass;
  DirectiveCompileResult(this._changeDetectorClass);

  List<o.Statement> get statements => [_changeDetectorClass];
}

class DirectiveCompiler {
  final ElementSchemaRegistry _schemaRegistry;
  final ViewNameResolver _nameResolver = DirectiveNameResolver();
  final CompileViewStorage _storage = CompileViewStorage();

  static final _emptySpan =
      SourceSpan(SourceLocation(0), SourceLocation(0), '');
  static final _implicitReceiver = o.ReadClassMemberExpr('instance');

  DirectiveCompiler(this._schemaRegistry);

  DirectiveCompileResult compile(CompileDirectiveMetadata directive) {
    assert(directive.requiresDirectiveChangeDetector);
    var classStmt = _buildChangeDetector(directive);
    return DirectiveCompileResult(classStmt);
  }

  o.ClassStmt _buildChangeDetector(CompileDirectiveMetadata directive) {
    var ctor = _createChangeDetectorConstructor(directive);

    var viewMethods = _buildDetectHostChanges(directive);

    var changeDetectorClass = o.ClassStmt(
        _changeDetectorClassName(directive),
        o.importExpr(Identifiers.DirectiveChangeDetector),
        _storage.fields ?? const [],
        const [],
        ctor,
        viewMethods,
        typeParameters: directive.originType.typeParameters);
    return changeDetectorClass;
  }

  static String _changeDetectorClassName(CompileDirectiveMetadata directive) =>
      '${directive.type.name}NgCd';

  o.ClassMethod _createChangeDetectorConstructor(
      CompileDirectiveMetadata directive) {
    var instanceType = o.importType(
      directive.type.identifier,
      typeArgumentsFrom(directive.originType.typeParameters),
    );
    ViewStorageItem instance = _storage.allocate(
      'instance',
      outputType: instanceType,
      modifiers: [
        o.StmtModifier.Final,
      ],
    );
    var statements = <o.Statement>[];
    if (_implementsOnChangesLifecycle(directive) ||
        _implementsComponentState(directive)) {
      statements.add(
          o.WriteClassMemberExpr('directive', _storage.buildReadExpr(instance))
              .toStmt());
    }
    var constructorArgs = [o.FnParam('this.instance')];
    if (_implementsComponentState(directive)) {
      constructorArgs.add(o.FnParam('v', o.importType(Identifiers.AppView)));
      constructorArgs
          .add(o.FnParam('e', o.importType(Identifiers.HTML_ELEMENT)));
      statements
          .add(o.WriteClassMemberExpr('view', o.ReadVarExpr('v')).toStmt());
      statements.add(o.WriteClassMemberExpr('el', o.ReadVarExpr('e')).toStmt());
      statements.add(o.InvokeMemberMethodExpr('initCd', const []).toStmt());
    }
    return o.ClassMethod(null, constructorArgs, statements);
  }

  static bool _implementsOnChangesLifecycle(
          CompileDirectiveMetadata directive) =>
      directive.lifecycleHooks.contains(LifecycleHooks.onChanges);

  static bool _implementsComponentState(CompileDirectiveMetadata directive) =>
      directive.changeDetection == ChangeDetectionStrategy.Stateful;

  List<o.ClassMethod> _buildDetectHostChanges(
      CompileDirectiveMetadata directive) {
    final hostProps = directive.hostProperties;
    if (hostProps.isEmpty) return [];

    List<BoundElementPropertyAst> hostProperties = <BoundElementPropertyAst>[];

    hostProps.forEach((String propName, ast.AST expression) {
      const securityContextElementName = 'div';
      hostProperties.add(createElementPropertyAst(
          securityContextElementName,
          propName,
          BoundExpression(expression),
          _emptySpan,
          _schemaRegistry,
          _reportError));
    });

    final CompileMethod method = CompileMethod();

    final _boundValueConverter = BoundValueConverter.forDirective(
        directive, _implicitReceiver, _nameResolver);

    bindAndWriteToRenderer(
      hostProperties,
      _boundValueConverter,
      o.variable('view'),
      o.variable('el'),
      false,
      _nameResolver,
      _storage,
      method,
    );

    var statements = method.finish();
    var readVars = method.findReadVarNames();

    if (readVars.contains(DetectChangesVars.firstCheck.name)) {
      statements.insert(0, _firstCheckVarStmt());
    }

    return [_detectHostChanges(statements)];
  }

  static o.DeclareVarStmt _firstCheckVarStmt() => o.DeclareVarStmt(
      DetectChangesVars.firstCheck.name,
      o
          .variable('view')
          .prop('cdState')
          .equals(o.literal(ChangeDetectorState.NeverChecked)),
      o.BOOL_TYPE);

  static o.ClassMethod _detectHostChanges(List<o.Statement> statements) =>
      o.ClassMethod(
          'detectHostChanges',
          [
            o.FnParam(
                'view', o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
            o.FnParam('el', o.importType(Identifiers.HTML_ELEMENT)),
          ],
          statements);

  static void _reportError(String message, SourceSpan sourceSpan,
      [ParseErrorLevel level]) {
    if (level == ParseErrorLevel.FATAL) {
      throwFailure(message);
    } else {
      logWarning(message);
    }
  }

  static String buildInputUpdateMethodName(String input) => 'ngSet\$$input';
}

class DirectiveNameResolver extends ViewNameResolver {
  DirectiveNameResolver() : super(null);

  @override
  void addLocal(String name, o.Expression e, [o.OutputType type]) {
    throw UnsupportedError('Locals are not supported in directives');
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
    throw UnsupportedError('Pipes are not support in directives');
  }
}
