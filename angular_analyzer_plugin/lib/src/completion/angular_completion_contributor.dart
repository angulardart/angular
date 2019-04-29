import 'dart:async';

import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/src/completion/template_completer.dart';

/// Computes angular autocompletions to contribute.
class AngularCompletionContributor extends CompletionContributor {
  /// Initialize a newly created handler for requests.
  AngularCompletionContributor();

  /// Asynchronously calculate the list of suggestions for the [request].
  @override
  Future<Null> computeSuggestions(
      AngularCompletionRequest request, CompletionCollector collector) async {
    final templates = request.templates;
    final standardHtml = request.standardHtml;
    final events = standardHtml.events.values.toList();
    final attributes = standardHtml.uniqueAttributeElements;

    final templateCompleter = TemplateCompleter();
    for (final template in templates) {
      await templateCompleter.computeSuggestions(
        request,
        collector,
        template,
        events,
        attributes,
      );
    }
  }
}
