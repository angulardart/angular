import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';

/// The angular-plugin-specific version of analyzer's [ResolverVisitor].
///
/// Overrides standard [ResolverVisitor] to prevent issues with analyzing
/// dangling angular nodes, while also allowing custom resolution of pipes. Not
/// intended as a long-term solution.
class AngularResolverVisitor extends _IntermediateResolverVisitor {
  final List<Pipe> pipes;

  AngularResolverVisitor(
      InheritanceManager3 inheritanceManager,
      LibraryElement library,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener,
      {@required this.pipes})
      : super(inheritanceManager, library, source, typeProvider, errorListener);

  @override
  void visitAsExpression(AsExpression exp) {
    // This means we generated this in a pipe, and its OK.
    // TODO(mfairhurst): figure out an alternative approach to this.
    if (exp.asOperator.offset == 0) {
      super.visitAsExpression(exp);
      final pipeName = exp.getProperty<SimpleIdentifier>('_ng_pipeName');
      final matchingPipes =
          pipes.where((pipe) => pipe.pipeName == pipeName.name);
      if (matchingPipes.isEmpty) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.PIPE_NOT_FOUND, pipeName, [pipeName]);
      } else if (matchingPipes.length > 1) {
        errorReporter.reportErrorForNode(
            AngularWarningCode.AMBIGUOUS_PIPE, pipeName, [pipeName]);
      } else {
        final matchingPipe = matchingPipes.single;
        exp.staticType = matchingPipe.transformReturnType;

        if (!typeSystem.isAssignableTo(
            exp.expression.staticType, matchingPipe.requiredArgumentType)) {
          errorReporter.reportErrorForNode(
              StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
              exp.expression,
              [exp.expression.staticType, matchingPipe.requiredArgumentType]);
        }
      }
    }
  }
}

/// Workaround for a harmless mixin application error.
///
/// See https://github.com/dart-lang/sdk/issues/15101 for details
///
/// Suppresses "This mixin application is invalid because all of the
/// constructors in the base class 'ResolverVisitor' have optional parameters."
/// in the definition of [AngularResolverVisitor].
class _IntermediateResolverVisitor extends ResolverVisitor {
  _IntermediateResolverVisitor(
      InheritanceManager3 inheritanceManager,
      LibraryElement library,
      Source source,
      TypeProvider typeProvider,
      AnalysisErrorListener errorListener)
      : super(inheritanceManager, library, source, typeProvider, errorListener);
}
