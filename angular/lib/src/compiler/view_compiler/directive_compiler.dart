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
import "../template_ast.dart" show BoundElementPropertyAst;
import '../template_parser.dart';
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
  final CompileDirectiveMetadata directive;
  final bool genDebugInfo;
  final bool hasOnChangesLifecycle;
  final bool hasAfterChangesLifecycle;
  final ElementSchemaRegistry _schemaRegistry;
  final viewMethods = <o.ClassMethod>[];
  final CompileViewStorage _storage = CompileViewStorage();

  bool _hasChangeDetector = false;
  bool _implementsComponentState;
  ViewNameResolver _nameResolver;

  DirectiveCompiler(this.directive, this._schemaRegistry, this.genDebugInfo)
      : hasOnChangesLifecycle =
            directive.lifecycleHooks.contains(LifecycleHooks.onChanges),
        hasAfterChangesLifecycle =
            directive.lifecycleHooks.contains(LifecycleHooks.afterChanges) {
    _implementsComponentState =
        directive.changeDetection == ChangeDetectionStrategy.Stateful;
  }

  DirectiveCompileResult compile() {
    assert(directive.requiresDirectiveChangeDetector);
    _nameResolver = DirectiveNameResolver();
    var classStmt = _buildChangeDetector();
    return DirectiveCompileResult(classStmt);
  }

  o.ClassStmt _buildChangeDetector() {
    var ctor = _createChangeDetectorConstructor(directive);

    _buildDetectHostChanges();
    var superClassExpr;
    if (hasOnChangesLifecycle ||
        hasAfterChangesLifecycle ||
        _hasChangeDetector) {
      superClassExpr = o.importExpr(Identifiers.DirectiveChangeDetector);
    }
    var changeDetectorClass = o.ClassStmt(
        changeDetectorClassName,
        // ignore: argument_type_not_assignable
        superClassExpr,
        _storage.fields ?? const [],
        const [],
        ctor,
        viewMethods,
        typeParameters: directive.originType.typeParameters);
    return changeDetectorClass;
  }

  bool get usesSetState =>
      _implementsComponentState && directive.hostProperties.isNotEmpty;

  o.ClassMethod _createChangeDetectorConstructor(
      CompileDirectiveMetadata meta) {
    var instanceType = o.importType(
      meta.type.identifier,
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
    if (hasOnChangesLifecycle || usesSetState) {
      statements.add(
          o.WriteClassMemberExpr('directive', _storage.buildReadExpr(instance))
              .toStmt());
    }
    var constructorArgs = [o.FnParam('this.instance')];
    if (usesSetState) {
      constructorArgs.add(o.FnParam('v', o.importType(Identifiers.AppView)));
      constructorArgs
          .add(o.FnParam('e', o.importType(Identifiers.HTML_ELEMENT)));
      statements
          .add(o.WriteClassMemberExpr('view', o.ReadVarExpr('v')).toStmt());
      statements.add(o.WriteClassMemberExpr('el', o.ReadVarExpr('e')).toStmt());
      statements.add(o.InvokeMemberMethodExpr('initCd', const []).toStmt());
    }
    // ignore: argument_type_not_assignable
    return o.ClassMethod(null, constructorArgs, statements);
  }

  void _buildDetectHostChanges() {
    final hostProps = directive.hostProperties;
    if (hostProps.isEmpty) return;
    // Create method with debug info turned off since we are no longer
    // generating directive bindings at call sites and it is directly
    // associated with directive itself. When an exception happens we
    // don't need to wrap including the call site template, the stack
    // trace will directly point to change detector.
    final CompileMethod method = CompileMethod(false);

    List<BoundElementPropertyAst> hostProperties = <BoundElementPropertyAst>[];

    var errorHandler =
        (String message, SourceSpan sourceSpan, [ParseErrorLevel level]) {
      if (level == ParseErrorLevel.FATAL) {
        throwFailure(message);
      } else {
        logWarning(message);
      }
    };

    var span = SourceSpan(SourceLocation(0), SourceLocation(0), '');
    hostProps.forEach((String propName, ast.AST expression) {
      const securityContextElementName = 'div';
      hostProperties.add(createElementPropertyAst(securityContextElementName,
          propName, expression, span, _schemaRegistry, errorHandler));
    });

    _hasChangeDetector = true;

    bindAndWriteToRenderer(
        hostProperties,
        o.variable('view'),
        o.ReadClassMemberExpr('instance'),
        directive,
        o.variable('el'),
        false,
        _nameResolver,
        _storage,
        method,
        genDebugInfo,
        updatingHostAttribute: true);

    var statements = method.finish();
    var readVars = method.findReadVarNames();

    if (readVars.contains(DetectChangesVars.firstCheck.name)) {
      statements.insert(
          0,
          o.DeclareVarStmt(
              DetectChangesVars.firstCheck.name,
              o
                  .variable('view')
                  .prop('cdState')
                  .equals(o.literal(ChangeDetectorState.NeverChecked)),
              o.BOOL_TYPE));
    }

    viewMethods.add(o.ClassMethod(
        'detectHostChanges',
        [
          o.FnParam(
              'view', o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
          o.FnParam('el', o.importType(Identifiers.HTML_ELEMENT)),
        ],
        statements));
  }

  static String buildInputUpdateMethodName(String input) => 'ngSet\$$input';

  String get changeDetectorClassName => '${directive.type.name}NgCd';
}

class DirectiveNameResolver extends ViewNameResolver {
  DirectiveNameResolver() : super(null);

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
