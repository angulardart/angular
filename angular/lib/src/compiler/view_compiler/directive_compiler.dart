import 'package:logging/logging.dart';
import 'package:source_span/source_span.dart';
import 'package:angular/src/core/metadata/lifecycle_hooks.dart';

import '../compile_metadata.dart' show CompileDirectiveMetadata;
import '../expression_parser/parser.dart' show Parser;
import '../identifiers.dart';
import '../output/output_ast.dart' as o;
import '../parse_util.dart' show ParseErrorLevel;
import '../schema/element_schema_registry.dart' show ElementSchemaRegistry;
import "../template_ast.dart" show BoundElementPropertyAst;
import '../template_parser.dart';
import 'compile_method.dart';
import 'constants.dart' show EventHandlerVars;
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
  final Parser _parser;
  final ElementSchemaRegistry _schemaRegistry;
  final viewMethods = <o.ClassMethod>[];

  bool _hasChangeDetector = false;
  ViewNameResolver _nameResolver;

  Logger _logger;

  DirectiveCompiler(
      this.directive, this._parser, this._schemaRegistry, this.genDebugInfo)
      : hasOnChangesLifecycle =
            directive.lifecycleHooks.contains(LifecycleHooks.OnChanges);

  DirectiveCompileResult compile() {
    assert(directive.requiresDirectiveChangeDetector);
    _nameResolver = new DirectiveNameResolver();
    var classStmt = _buildChangeDetector();
    return new DirectiveCompileResult(classStmt);
  }

  Logger get logger => _logger ??= new Logger('View Compiler');

  o.ClassStmt _buildChangeDetector() {
    var ctor = _createChangeDetectorConstructor(directive);

    _buildDetectHostChanges();
    var superClassExpr;
    if (hasOnChangesLifecycle || _hasChangeDetector) {
      superClassExpr = o.importExpr(Identifiers.DirectiveChangeDetector);
    }
    var changeDetectorClass = new o.ClassStmt(
        changeDetectorClassName,
        superClassExpr,
        _nameResolver.fields ?? const [],
        const [],
        ctor,
        viewMethods);
    return changeDetectorClass;
  }

  o.ClassMethod _createChangeDetectorConstructor(
      CompileDirectiveMetadata meta) {
    var instanceType = o.importType(meta.type.identifier);
    _nameResolver.addField(new o.ClassField(
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

  void _buildDetectHostChanges() {
    final hostProps = directive.hostProperties;
    if (hostProps.isEmpty) return;
    // Create method with debug info turned off since we are no longer
    // generating directive bindings at call sites and it is directly
    // associated with directive itself. When an exception happens we
    // don't need to wrap including the call site template, the stack
    // trace will directly point to change detector.
    final CompileMethod method = new CompileMethod(false);

    List<BoundElementPropertyAst> hostProperties = <BoundElementPropertyAst>[];

    var errorHandler =
        (String message, SourceSpan sourceSpan, [ParseErrorLevel level]) {
      if (level == ParseErrorLevel.FATAL) {
        logger.severe(message);
      } else {
        logger.warning(message);
      }
    };

    var span = new SourceSpan(new SourceLocation(0), new SourceLocation(0), '');
    hostProps.forEach((String propName, String expression) {
      var exprAst = _parser.parseBinding(expression, null, directive.exports);
      const securityContextElementName = 'div';
      hostProperties.add(createElementPropertyAst(securityContextElementName,
          propName, exprAst, span, _schemaRegistry, errorHandler));
    });

    _hasChangeDetector = true;

    bindAndWriteToRenderer(
        hostProperties,
        o.variable('view'),
        new o.ReadClassMemberExpr('instance'),
        directive,
        o.variable('el'),
        false,
        _nameResolver,
        method,
        genDebugInfo,
        updatingHost: true);

    viewMethods.add(new o.ClassMethod(
        'detectHostChanges',
        [
          new o.FnParam(
              'view', o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE])),
          new o.FnParam('el', o.importType(Identifiers.HTML_ELEMENT)),
          new o.FnParam('firstCheck', o.BOOL_TYPE),
        ],
        method.finish()));
  }

  static String buildInputUpdateMethodName(String input) => 'ngSet\$$input';

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
