import 'package:source_span/source_span.dart';
import 'package:angular/src/core/change_detection/change_detection.dart'
    show ChangeDetectorState;
import 'package:angular_compiler/cli.dart';

import '../identifiers.dart';
import '../ir/model.dart' as ir;
import '../output/convert.dart' show typeArgumentsFrom;
import '../output/output_ast.dart' as o;
import '../parse_util.dart' show ParseErrorLevel;
import '../schema/element_schema_registry.dart' show ElementSchemaRegistry;
import '../template_ast.dart' show BoundExpression;
import '../template_parser.dart';
import 'bound_value_converter.dart';
import 'compile_method.dart';
import 'compile_view.dart' show CompileViewStorage, NodeReference;
import 'constants.dart' show DetectChangesVars, EventHandlerVars;
import 'property_binder.dart' show bindAndWriteToRenderer;
import 'view_name_resolver.dart';

class DirectiveCompileResult {
  final List<o.Statement> statements;

  DirectiveCompileResult(o.ClassStmt changeDetectorClass)
      : statements = [changeDetectorClass];
}

class DirectiveCompiler {
  final ElementSchemaRegistry _schemaRegistry;

  static final _emptySpan = SourceSpan(
    SourceLocation(0),
    SourceLocation(0),
    '',
  );
  static final _implicitReceiver = o.ReadClassMemberExpr('instance');

  DirectiveCompiler(this._schemaRegistry);

  DirectiveCompileResult compile(ir.Directive directive) {
    assert(directive.requiresDirectiveChangeDetector);
    final nameResolver = DirectiveNameResolver();
    final storage = CompileViewStorage();
    final classStmt = _buildChangeDetector(directive, nameResolver, storage);
    return DirectiveCompileResult(classStmt);
  }

  o.ClassStmt _buildChangeDetector(
    ir.Directive directive,
    ViewNameResolver nameResolver,
    CompileViewStorage storage,
  ) {
    final el = NodeReference.parameter(
        storage, o.importType(Identifiers.HTML_ELEMENT), 'el');
    final constructor = _createChangeDetectorConstructor(
      directive,
      storage,
      el,
    );
    final viewMethods = _buildDetectHostChanges(
      directive,
      nameResolver,
      storage,
      el,
    );
    return o.ClassStmt(
      _changeDetectorClassName(directive),
      o.importExpr(Identifiers.DirectiveChangeDetector),
      storage.fields ?? const [],
      const [],
      constructor,
      viewMethods,
      typeParameters: directive.typeParameters,
    );
  }

  static String _changeDetectorClassName(ir.Directive directive) =>
      '${directive.name}NgCd';

  o.Constructor _createChangeDetectorConstructor(
    ir.Directive directive,
    CompileViewStorage storage,
    NodeReference el,
  ) {
    final instanceType = o.importType(
      directive.metadata.type.identifier,
      typeArgumentsFrom(directive.typeParameters),
    );
    final instance = storage.allocate(
      'instance',
      outputType: instanceType,
      modifiers: [
        o.StmtModifier.Final,
      ],
    );
    final statements = <o.Statement>[];
    if (_implementsOnChangesLifecycle(directive) ||
        _implementsComponentState(directive)) {
      final setDirective = o.WriteClassMemberExpr(
        'directive',
        storage.buildReadExpr(instance),
      );
      statements.add(setDirective.toStmt());
    }
    final constructorArgs = [o.FnParam('this.instance')];
    if (_implementsComponentState(directive)) {
      constructorArgs
        ..add(o.FnParam('v', o.importType(Identifiers.AppView)))
        ..add(o.FnParam('e', o.importType(Identifiers.HTML_ELEMENT)));
      statements.addAll([
        o.WriteClassMemberExpr('view', o.ReadVarExpr('v')).toStmt(),
        el.toWriteStmt(o.ReadVarExpr('e')),
        o.InvokeMemberMethodExpr('initCd', const []).toStmt()
      ]);
    }
    return o.Constructor(params: constructorArgs, body: statements);
  }

  static bool _implementsOnChangesLifecycle(ir.Directive directive) =>
      directive.implementsOnChanges;

  static bool _implementsComponentState(ir.Directive directive) =>
      directive.implementsComponentState;

  List<o.ClassMethod> _buildDetectHostChanges(
    ir.Directive directive,
    ViewNameResolver nameResolver,
    CompileViewStorage storage,
    NodeReference el,
  ) {
    final hostProps = directive.hostProperties;
    if (hostProps.isEmpty) {
      return [];
    }
    const securityContextElementName = 'div';

    final hostProperties = hostProps.entries.map((entry) {
      final property = entry.key;
      final expression = entry.value;
      return createElementPropertyAst(
        securityContextElementName,
        property,
        BoundExpression(expression),
        _emptySpan,
        _schemaRegistry,
        _reportError,
      );
    }).toList();

    final CompileMethod method = CompileMethod();

    final _boundValueConverter = BoundValueConverter.forDirective(
      directive.metadata,
      _implicitReceiver,
      nameResolver,
    );

    bindAndWriteToRenderer(
      hostProperties,
      _boundValueConverter,
      o.variable('view'),
      el,
      false,
      nameResolver,
      storage,
      method,
    );

    final statements = method.finish();
    final readVars = method.findReadVarNames();

    if (readVars.contains(DetectChangesVars.firstCheck.name)) {
      statements.insert(0, _firstCheckVarStmt);
    }

    return [_detectHostChanges(statements)];
  }

  /// Determines whether this is the first time the view was checked for change.
  static final _firstCheckVarStmt = o.DeclareVarStmt(
    DetectChangesVars.firstCheck.name,
    o
        .variable('view')
        .prop('cdState')
        .equals(o.literal(ChangeDetectorState.NeverChecked)),
    o.BOOL_TYPE,
  );

  static o.ClassMethod _detectHostChanges(List<o.Statement> statements) {
    // We create a method that can detect a host AppView/rootElement.
    //
    // void detectHostChanges(AppView<dynamic> view, Element el) { ... }
    return o.ClassMethod(
      'detectHostChanges',
      [
        o.FnParam(
          'view',
          o.importType(Identifiers.AppView, [o.DYNAMIC_TYPE]),
        ),
        o.FnParam(
          'el',
          o.importType(Identifiers.HTML_ELEMENT),
        ),
      ],
      statements,
    );
  }

  static void _reportError(
    String message,
    SourceSpan sourceSpan, [
    ParseErrorLevel level,
  ]) {
    if (level == ParseErrorLevel.FATAL) {
      throwFailure(message);
    } else {
      logWarning(message);
    }
  }
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
    String name,
    o.Expression input,
    List<o.Expression> args,
  ) {
    throw UnsupportedError('Pipes are not support in directives');
  }
}
