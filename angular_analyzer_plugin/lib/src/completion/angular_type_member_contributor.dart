import 'dart:async';

import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/type_member_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/src/completion/dart_resolve_result_shell.dart';
import 'package:angular_analyzer_plugin/ast.dart';

/// Completion contributor for typed members in an angular context.
///
/// Extension of [TypeMemberContributor] to allow for Dart-based
/// completion within Angular context. Triggered in [StatementsBoundAttribute],
/// [ExpressionsBoundAttribute], [Mustache], and [TemplateAttribute]
/// on member variable completion.
class AngularTypeMemberContributor extends CompletionContributor {
  final TypeMemberContributor _typeMemberContributor = TypeMemberContributor();

  @override
  Future<Null> computeSuggestions(
      AngularCompletionRequest request, CompletionCollector collector) async {
    final templates = request.templates;

    for (final template in templates) {
      final typeProvider = template.component.classElement.enclosingElement
          .enclosingElement.context.typeProvider;
      final dartSnippet = request.dartSnippet;

      if (dartSnippet != null) {
        final classElement = template.component.classElement;
        final libraryElement = classElement.library;

        final dartResolveResult = DartResolveResultShell(request.path,
            libraryElement: libraryElement, typeProvider: typeProvider);
        final dartRequest = DartCompletionRequestImpl(
            request.resourceProvider, request.offset, dartResolveResult);
        await _typeMemberContributor.computeSuggestionsWithEntryPoint(
            dartRequest, collector, dartSnippet);
      }
    }
  }
}
