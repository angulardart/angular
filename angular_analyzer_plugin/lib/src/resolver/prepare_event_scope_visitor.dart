import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/resolver/angular_scope_visitor.dart';
import 'package:angular_analyzer_plugin/src/resolver/dart_variable_manager.dart';
import 'package:angular_analyzer_plugin/src/resolver/is_on_custom_tag.dart';

/// Resolve [OutputBinding]s on the attributes, and define `$event` variables.
///
/// Requires previous resolution of directives to match the outputs to those
/// that exist.
class PrepareEventScopeVisitor extends AngularScopeVisitor {
  List<DirectiveBase> directives;
  final Template template;
  final Source templateSource;
  final Map<String, LocalVariable> localVariables;
  final Map<String, Output> standardHtmlEvents;
  final TypeProvider typeProvider;
  final DartVariableManager dartVariableManager;
  final AnalysisErrorListener errorListener;

  PrepareEventScopeVisitor(
      this.standardHtmlEvents,
      this.template,
      this.templateSource,
      this.localVariables,
      this.typeProvider,
      this.dartVariableManager,
      this.errorListener);

  @override
  void visitElementInfo(ElementInfo elem) {
    directives = elem.directives;
    super.visitElementInfo(elem);
  }

  @override
  void visitStatementsBoundAttr(StatementsBoundAttribute attr) {
    if (attr.reductions.isNotEmpty &&
        attr.name != 'keyup' &&
        attr.name != 'keydown') {
      errorListener.onError(AnalysisError(
          templateSource,
          attr.reductionsOffset,
          attr.reductionsLength,
          AngularWarningCode.EVENT_REDUCTION_NOT_ALLOWED));
    }

    var eventType = typeProvider.dynamicType;
    var matched = false;

    for (final directiveBinding in attr.parent.boundDirectives) {
      for (final output in directiveBinding.boundDirective.outputs) {
        //TODO what if this matches two directives?
        if (output.name == attr.name) {
          eventType = output.eventType;
          matched = true;
          final range = SourceRange(attr.nameOffset, attr.name.length);
          template.addRange(range, output);
          directiveBinding.outputBindings.add(OutputBinding(output, attr));
        }
      }
    }

    //standard HTML events bubble up, so everything supports them
    if (!matched) {
      final standardHtmlEvent = standardHtmlEvents[attr.name];
      if (standardHtmlEvent != null) {
        matched = true;
        eventType = standardHtmlEvent.eventType;
        final range = SourceRange(attr.nameOffset, attr.name.length);
        template.addRange(range, standardHtmlEvent);
        attr.parent.boundStandardOutputs
            .add(OutputBinding(standardHtmlEvent, attr));
      }
    }

    if (!matched && !isOnCustomTag(attr)) {
      errorListener.onError(AnalysisError(
          templateSource,
          attr.nameOffset,
          attr.name.length,
          AngularWarningCode.NONEXIST_OUTPUT_BOUND,
          [attr.name]));
    }

    attr.localVariables = HashMap.from(localVariables);
    final localVariableElement =
        dartVariableManager.newLocalVariableElement(-1, r'$event', eventType);
    final localVariable = LocalVariable(r'$event', localVariableElement);
    attr.localVariables[r'$event'] = localVariable;
  }

  @override
  void visitTemplateAttr(TemplateAttribute templateAttr) {
    directives = templateAttr.directives;
    super.visitTemplateAttr(templateAttr);
  }
}
