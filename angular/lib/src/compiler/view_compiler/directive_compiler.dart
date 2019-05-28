import 'package:angular/src/compiler/identifiers.dart';
import 'package:angular/src/compiler/ir/model.dart' as ir;
import 'package:angular/src/compiler/output/convert.dart'
    show typeArgumentsFrom;
import 'package:angular/src/compiler/output/output_ast.dart' as o;

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
  static final _implicitReceiver = o.ReadClassMemberExpr('instance');

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
    storage.allocate(
      'instance',
      outputType: instanceType,
      modifiers: [
        o.StmtModifier.Final,
      ],
    );
    final constructorArgs = [o.FnParam('this.instance')];
    return o.Constructor(params: constructorArgs);
  }

  List<o.ClassMethod> _buildDetectHostChanges(
    ir.Directive directive,
    ViewNameResolver nameResolver,
    CompileViewStorage storage,
    NodeReference el,
  ) {
    final hostProperties = directive.hostProperties;
    if (hostProperties.isEmpty) {
      return [];
    }

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
    o.variable('view').prop('firstCheck'),
    o.BOOL_TYPE,
  );

  static o.ClassMethod _detectHostChanges(List<o.Statement> statements) {
    // We create a method that can detect a host RenderView/rootElement.
    //
    // void detectHostChanges(RenderView view, Element el) { ... }
    return o.ClassMethod(
      'detectHostChanges',
      [
        o.FnParam('view', o.importType(Views.renderView)),
        o.FnParam('el', o.importType(Identifiers.HTML_ELEMENT)),
      ],
      statements,
    );
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
