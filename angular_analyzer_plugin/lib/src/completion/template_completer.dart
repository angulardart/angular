import 'dart:async';

import 'package:analyzer/dart/element/type_system.dart' show TypeSystem;
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:angular_analyzer_plugin/src/completion/offset_contained.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/or_selector.dart';

/// Suggest angular/html (non-dart) completions for a single [Template].
///
/// Note that one HTML file may have multiple [Template]s, if it is referenced
/// by two different components via `templateUrl`. For this reason, this is not
/// a completion contributor (which can only run once), but rather its own class
/// which is then called by [AngularCompletionContributor] once per [Template]
/// value.
///
/// Suggests things like:
///
/// - HTML tags
/// - input binding attributes
/// - output binding attributes
/// - banana attributes
/// - star attributes
/// - exportAs identfiers
///
/// Does not do dart suggestions, only non-dart html concepts.
class TemplateCompleter {
  static const int RELEVANCE_TRANSCLUSION = DART_RELEVANCE_DEFAULT + 10;

  Future<Null> computeSuggestions(
    AngularCompletionRequest request,
    CompletionCollector collector,
    Template template,
    List<Output> standardHtmlEvents,
    Set<Input> standardHtmlAttributes,
  ) async {
    var analysisContext = template
        .component.classElement.enclosingElement.enclosingElement.context;
    final typeSystem = analysisContext.typeSystem;
    final typeProvider = analysisContext.typeProvider;
    final dartSnippet = request.dartSnippet;
    final target = request.angularTarget;

    if (dartSnippet != null) {
      return;
    }

    if (target is ElementInfo) {
      if (target.closingSpan != null &&
          offsetContained(request.offset, target.closingSpan.offset,
              target.closingSpan.length)) {
        if (request.offset ==
            (target.closingSpan.offset + target.closingSpan.length)) {
          // In closing tag, but could be directly after it; ex: '</div>^'.
          suggestHtmlTags(template, collector);
          if (target.parent != null && target.parent is! DocumentInfo) {
            suggestTransclusions(target.parent, collector);
          }
        }
      } else if (!offsetContained(request.offset, target.openingNameSpan.offset,
          target.openingNameSpan.length)) {
        // If request is not in [openingNameSpan], suggest decorators.
        suggestInputs(
          target.boundDirectives,
          collector,
          standardHtmlAttributes,
          target.boundStandardInputs,
          typeSystem,
          typeProvider,
          includePlainAttributes: true,
        );
        suggestOutputs(
          target.boundDirectives,
          collector,
          standardHtmlEvents,
          target.boundStandardOutputs,
        );
        suggestBananas(
          target.boundDirectives,
          collector,
          target.boundStandardInputs,
          target.boundStandardOutputs,
        );
        suggestFromAvailableDirectives(
          target.availableDirectives,
          collector,
          suggestPlainAttributes: true,
          suggestInputs: true,
          suggestBananas: true,
        );
        if (!target.isOrHasTemplateAttribute) {
          suggestStarAttrs(template, collector);
        }
      } else {
        // Otherwise, suggest HTML tags and transclusions.
        suggestHtmlTags(template, collector);
        if (target.parent != null || target.parent is! DocumentInfo) {
          suggestTransclusions(target.parent, collector);
        }
      }
    } else if (target is AttributeInfo && target.parent is TemplateAttribute) {
      final templateAttr = target.parent as TemplateAttribute;
      // `let foo`. Nothing to suggest.
      if (target is TextAttribute && target.name.startsWith("let-")) {
        return;
      }

      if (offsetContained(request.offset, target.originalNameOffset,
          target.originalName.length)) {
        suggestInputsInTemplate(templateAttr, collector, currentAttr: target);
      } else {
        suggestInputsInTemplate(templateAttr, collector);
      }
    } else if (target is ExpressionBoundAttribute &&
        offsetContained(request.offset, target.originalNameOffset,
            target.originalName.length)) {
      final _suggestInputs = target.bound == ExpressionBoundType.input;
      var _suggestBananas = target.bound == ExpressionBoundType.twoWay;

      if (_suggestInputs) {
        _suggestBananas = target.nameOffset == request.offset;
        suggestInputs(
            target.parent.boundDirectives,
            collector,
            standardHtmlAttributes,
            target.parent.boundStandardInputs,
            typeSystem,
            typeProvider,
            currentAttr: target);
      }
      if (_suggestBananas) {
        suggestBananas(
          target.parent.boundDirectives,
          collector,
          target.parent.boundStandardInputs,
          target.parent.boundStandardOutputs,
          currentAttr: target,
        );
      }
      suggestFromAvailableDirectives(
        target.parent.availableDirectives,
        collector,
        suggestBananas: _suggestBananas,
        suggestInputs: _suggestInputs,
      );
    } else if (target is StatementsBoundAttribute) {
      suggestOutputs(target.parent.boundDirectives, collector,
          standardHtmlEvents, target.parent.boundStandardOutputs,
          currentAttr: target);
    } else if (target is TemplateAttribute) {
      if (offsetContained(request.offset, target.originalNameOffset,
          target.originalName.length)) {
        suggestStarAttrs(template, collector);
      }
      suggestInputsInTemplate(target, collector);
    } else if (target is TextAttribute && target.nameOffset != null) {
      if (offsetContained(
          request.offset, target.nameOffset, target.name.length)) {
        suggestInputs(
            target.parent.boundDirectives,
            collector,
            standardHtmlAttributes,
            target.parent.boundStandardInputs,
            typeSystem,
            typeProvider,
            includePlainAttributes: true);
        suggestOutputs(target.parent.boundDirectives, collector,
            standardHtmlEvents, target.parent.boundStandardOutputs);
        suggestBananas(
          target.parent.boundDirectives,
          collector,
          target.parent.boundStandardInputs,
          target.parent.boundStandardOutputs,
        );
        suggestFromAvailableDirectives(
          target.parent.availableDirectives,
          collector,
          suggestPlainAttributes: true,
          suggestInputs: true,
          suggestBananas: true,
        );
      } else if (target.value != null &&
          target.isReference &&
          offsetContained(
              request.offset, target.valueOffset, target.value.length)) {
        suggestRefValues(target.parent.boundDirectives, collector);
      }
    } else if (target is TextInfo) {
      suggestHtmlTags(template, collector);
      suggestTransclusions(target.parent, collector);
    }
  }

  void suggestBananas(
      List<DirectiveBinding> directives,
      CompletionCollector collector,
      List<InputBinding> boundStandardAttributes,
      List<OutputBinding> boundStandardOutputs,
      {BoundAttributeInfo currentAttr}) {
    // Handle potential two-way found in bound directives
    // There are no standard event/attribute that fall under two-way binding.
    for (final directive in directives) {
      final usedInputs = directive.inputBindings
          .where((b) => b.attribute != currentAttr)
          .map((b) => b.boundInput)
          .toSet();
      final usedOutputs = directive.outputBindings
          .where((b) => b.attribute != currentAttr)
          .map((b) => b.boundOutput)
          .toSet();

      final availableInputs =
          directive.boundDirective.inputs.toSet().difference(usedInputs);
      final availableOutputs =
          directive.boundDirective.outputs.toSet().difference(usedOutputs);
      for (final input in availableInputs) {
        final inputName = input.name;
        final complementName = '${inputName}Change';
        final output = availableOutputs
            .firstWhere((o) => o.name == complementName, orElse: () => null);
        if (output != null) {
          collector.addSuggestion(_createBananaSuggestion(
              input,
              DART_RELEVANCE_DEFAULT,
              _createBananaElement(input, ElementKind.SETTER)));
        }
      }
    }
  }

  /// Suggest attributes that will result in a bound directive.
  ///
  /// Goes through all the available, but not yet-bound directives and extracts
  /// non-violating plain-text attribute-directives and inputs (if name overlaps
  /// with attribute-directive).
  void suggestFromAvailableDirectives(
    Map<DirectiveBase, List<SelectorName>> availableDirectives,
    CompletionCollector collector, {
    bool suggestInputs = false,
    bool suggestBananas = false,
    bool suggestPlainAttributes = false,
  }) {
    availableDirectives.forEach((directive, selectors) {
      final attributeSelectors = <String, SelectorName>{};
      final validInputs = <Input>[];

      for (final attribute in selectors) {
        attributeSelectors[attribute.string] = attribute;
      }

      for (final input in directive.inputs) {
        if (attributeSelectors.keys.contains(input.name)) {
          attributeSelectors.remove(input.name);
          validInputs.add(input);
        }
      }

      for (final input in validInputs) {
        final outputComplement = '${input.name}Change';
        final output = directive.outputs.firstWhere(
            (output) => output.name == outputComplement,
            orElse: () => null);
        if (output != null && suggestBananas) {
          collector.addSuggestion(_createBananaSuggestion(
              input,
              DART_RELEVANCE_DEFAULT,
              _createBananaElement(input, ElementKind.SETTER)));
        }
        if (suggestInputs) {
          collector.addSuggestion(_createInputSuggestion(input,
              DART_RELEVANCE_DEFAULT, _createInput(input, ElementKind.SETTER)));
        }
      }

      if (suggestPlainAttributes) {
        attributeSelectors.forEach((name, selector) {
          final nameOffset = selector.navigationRange.offset;
          final locationSource = selector.source.fullName;
          collector.addSuggestion(_createPlainAttributeSuggestions(
              name,
              DART_RELEVANCE_DEFAULT,
              _createPlainAttributeElement(
                  name, nameOffset, locationSource, ElementKind.SETTER)));
        });
      }
    });
  }

  void suggestHtmlTags(Template template, CompletionCollector collector) {
    final elementTagMap = template.component.elementTagsInfo;
    for (final elementTagName in elementTagMap.keys) {
      final currentSuggestion = _createHtmlTagSuggestion(
          '<$elementTagName',
          DART_RELEVANCE_DEFAULT,
          _createHtmlTagElement(
              elementTagName,
              elementTagMap[elementTagName].first,
              ElementKind.CLASS_TYPE_ALIAS));
      if (currentSuggestion != null) {
        collector.addSuggestion(currentSuggestion);
      }
    }
  }

  void suggestInputs(
    List<DirectiveBinding> directives,
    CompletionCollector collector,
    Set<Input> standardHtmlAttributes,
    List<InputBinding> boundStandardAttributes,
    TypeSystem typeSystem,
    TypeProvider typeProvider, {
    ExpressionBoundAttribute currentAttr,
    bool includePlainAttributes = false,
  }) {
    for (final directive in directives) {
      final usedInputs = directive.inputBindings
          .where((b) => b.attribute != currentAttr)
          .map((b) => b.boundInput)
          .toSet();

      for (final input in directive.boundDirective.inputs) {
        // don't recommend [name] [name] [name]
        if (usedInputs.contains(input)) {
          continue;
        }

        if (includePlainAttributes && typeProvider != null) {
          if (typeSystem.isAssignableTo(
              typeProvider.stringType, input.setterType)) {
            final relevance = input.setterType.displayName == 'String'
                ? DART_RELEVANCE_DEFAULT
                : DART_RELEVANCE_DEFAULT - 1;
            collector.addSuggestion(_createPlainAttributeSuggestions(
                input.name,
                relevance,
                _createPlainAttributeElement(
                  input.name,
                  input.nameRange.offset,
                  input.source.fullName,
                  ElementKind.SETTER,
                )));
          }
        }
        collector.addSuggestion(_createInputSuggestion(input,
            DART_RELEVANCE_DEFAULT, _createInput(input, ElementKind.SETTER)));
      }
    }

    final usedStdInputs = boundStandardAttributes
        .where((b) => b.attribute != currentAttr)
        .map((b) => b.boundInput)
        .toSet();

    for (final input in standardHtmlAttributes) {
      // TODO don't recommend [hidden] [hidden] [hidden]
      if (usedStdInputs.contains(input)) {
        continue;
      }
      if (includePlainAttributes && typeProvider != null) {
        if (typeSystem.isAssignableTo(
            typeProvider.stringType, input.setterType)) {
          final relevance = input.setterType.displayName == 'String'
              ? DART_RELEVANCE_DEFAULT - 2
              : DART_RELEVANCE_DEFAULT - 3;
          collector.addSuggestion(_createPlainAttributeSuggestions(
              input.name,
              relevance,
              _createPlainAttributeElement(
                input.name,
                input.nameRange.offset,
                input.source.fullName,
                ElementKind.SETTER,
              )));
        }
      }
      collector.addSuggestion(_createInputSuggestion(input,
          DART_RELEVANCE_DEFAULT - 2, _createInput(input, ElementKind.SETTER)));
    }
  }

  void suggestInputsInTemplate(
      TemplateAttribute templateAttr, CompletionCollector collector,
      {AttributeInfo currentAttr}) {
    final directives = templateAttr.boundDirectives;
    for (final binding in directives) {
      final usedInputs = binding.inputBindings
          .where((b) => b.attribute != currentAttr)
          .map((b) => b.boundInput)
          .toSet();

      for (final input in binding.boundDirective.inputs) {
        // don't recommend trackBy: x trackBy: x trackBy: x
        if (usedInputs.contains(input)) {
          continue;
        }

        // edge case. Don't think this comes up in standard.
        if (!input.name.startsWith(templateAttr.prefix)) {
          continue;
        }

        // Unlike ngForTrackBy becoming trackBy, ngFor can't become anything.
        if (input.name == templateAttr.prefix) {
          continue;
        }

        collector.addSuggestion(_createInputInTemplateSuggestion(
            templateAttr.prefix,
            input,
            DART_RELEVANCE_DEFAULT,
            _createInput(input, ElementKind.SETTER)));
      }
    }
  }

  void suggestOutputs(
      List<DirectiveBinding> directives,
      CompletionCollector collector,
      List<Output> standardHtmlEvents,
      List<OutputBinding> boundStandardOutputs,
      {BoundAttributeInfo currentAttr}) {
    for (final directive in directives) {
      final usedOutputs = directive.outputBindings
          .where((b) => b.attribute != currentAttr)
          .map((b) => b.boundOutput)
          .toSet();
      for (final output in directive.boundDirective.outputs) {
        // don't recommend (close) (close) (close)
        if (usedOutputs.contains(output)) {
          continue;
        }
        collector.addSuggestion(_createOutputSuggestion(
            output,
            DART_RELEVANCE_DEFAULT,
            _createOutputElement(output, ElementKind.GETTER)));
      }
    }

    final usedStdOutputs = boundStandardOutputs
        .where((b) => b.attribute != currentAttr)
        .map((b) => b.boundOutput)
        .toSet();

    for (final output in standardHtmlEvents) {
      // don't recommend (click) (click) (click)
      if (usedStdOutputs.contains(output)) {
        continue;
      }
      collector.addSuggestion(_createOutputSuggestion(
          output,
          DART_RELEVANCE_DEFAULT - 1, // just below regular relevance
          _createOutputElement(output, ElementKind.GETTER)));
    }
  }

  void suggestRefValues(
      List<DirectiveBinding> directives, CompletionCollector collector) {
    // Keep map of all 'exportAs' name seen. Don't suggest same name twice.
    // If two directives share same exportAs, still suggest one of them
    // and if they use this, and error will flag - let user resolve
    // rather than not suggesting at all.
    final seen = <String>{};
    for (final directive in directives) {
      final exportAs = directive.boundDirective.exportAs;
      if (exportAs != null && exportAs.string.isNotEmpty) {
        final exportAsName = exportAs.string;
        if (!seen.contains(exportAsName)) {
          seen.add(exportAsName);
          collector.addSuggestion(_createRefValueSuggestion(
              exportAs,
              DART_RELEVANCE_DEFAULT,
              _createRefValueElement(exportAs, ElementKind.LABEL)));
        }
      }
    }
  }

  void suggestStarAttrs(Template template, CompletionCollector collector) {
    template.component.directives.where((d) => d.looksLikeTemplate).forEach(
        (directive) =>
            suggestStarAttrsForSelector(directive.selector, collector));
  }

  void suggestStarAttrsForSelector(
      Selector selector, CompletionCollector collector) {
    if (selector is OrSelector) {
      for (final subselector in selector.selectors) {
        suggestStarAttrsForSelector(subselector, collector);
      }
    } else if (selector is AndSelector) {
      for (final subselector in selector.selectors) {
        suggestStarAttrsForSelector(subselector, collector);
      }
    } else if (selector is AttributeSelector) {
      if (selector.nameElement.string == "ngForOf") {
        // `ngFor`'s selector includes `[ngForOf]`, but `*ngForOf=..` won't ever
        // work, because it then becomes impossible to satisfy the other half,
        // `[ngFor]`. Hardcode to filter this out, rather than using some kind
        // of complex heuristic.
        return;
      }

      collector.addSuggestion(_createStarAttrSuggestion(
          selector,
          DART_RELEVANCE_DEFAULT,
          _createStarAttrElement(selector, ElementKind.CLASS)));
    }
  }

  void suggestTransclusions(
      ElementInfo container, CompletionCollector collector) {
    for (final directive in container.directives) {
      if (directive is! Component) {
        continue;
      }

      final component = directive as Component;

      for (final ngContent in component.ngContents) {
        if (ngContent.selector == null) {
          continue;
        }

        final tags = ngContent.selector.suggestTags();
        for (final tag in tags) {
          final location = Location(component.templateSource.fullName,
              ngContent.sourceRange.offset, ngContent.sourceRange.length, 0, 0);
          collector.addSuggestion(_createHtmlTagSuggestion(
              tag.toString(),
              RELEVANCE_TRANSCLUSION,
              _createHtmlTagTransclusionElement(
                  tag.toString(), ElementKind.CLASS_TYPE_ALIAS, location)));
        }
      }
    }
  }

  Element _createBananaElement(Input input, ElementKind kind) {
    final name = '[(${input.name})]';
    final location = Location(input.source.fullName, input.nameRange.offset,
        input.nameRange.length, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags,
        location: location, returnType: input.setterType.toString());
  }

  CompletionSuggestion _createBananaSuggestion(
      Input input, int defaultRelevance, Element element) {
    final completion = '[(${input.name})]';
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element, returnType: input.setterType.toString());
  }

  Element _createHtmlTagElement(
      String elementTagName, DirectiveBase directive, ElementKind kind) {
    final elementTags = <ElementNameSelector>[];
    directive.selector.recordElementNameSelectors(elementTags);
    final selector = elementTags.firstWhere(
        (currSelector) => currSelector.toString() == elementTagName);
    final offset = selector.nameElement.navigationRange.offset;
    final length = selector.nameElement.navigationRange.length;

    final location = Location(directive.source.fullName, offset, length, 0, 0);
    final flags = Element.makeFlags(
        isAbstract: false, isDeprecated: false, isPrivate: false);
    return Element(kind, '<$elementTagName', flags, location: location);
  }

  CompletionSuggestion _createHtmlTagSuggestion(
          String elementTagName, int defaultRelevance, Element element) =>
      CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          defaultRelevance,
          elementTagName,
          elementTagName.length,
          0,
          false,
          false,
          element: element);

  Element _createHtmlTagTransclusionElement(
      String elementTagName, ElementKind kind, Location location) {
    final flags = Element.makeFlags(
        isAbstract: false, isDeprecated: false, isPrivate: false);
    return Element(kind, elementTagName, flags, location: location);
  }

  Element _createInput(Input input, ElementKind kind) {
    final name = '[${input.name}]';
    final location = Location(input.source.fullName, input.nameRange.offset,
        input.nameRange.length, 0, 0);
    final flags = Element.makeFlags(
        isAbstract: false, isDeprecated: false, isPrivate: false);
    return Element(kind, name, flags, location: location);
  }

  CompletionSuggestion _createInputInTemplateSuggestion(
      String prefix, Input input, int defaultRelevance, Element element) {
    final capitalized = input.name.substring(prefix.length);
    final firstLetter = capitalized.substring(0, 1).toLowerCase();
    final remaining = capitalized.substring(1);
    final completion = '$firstLetter$remaining:';
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element);
  }

  CompletionSuggestion _createInputSuggestion(
      Input input, int defaultRelevance, Element element) {
    final completion = '[${input.name}]';
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element);
  }

  Element _createOutputElement(Output output, ElementKind kind) {
    final name = '(${output.name})';
    // Note: We use `?? 0` below because focusin/out don't have ranges but we
    // still want to suggest them.
    final location = Location(output.source?.fullName,
        output.nameRange?.offset ?? 0, output.nameRange?.length ?? 0, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags,
        location: location, returnType: output.eventType.toString());
  }

  CompletionSuggestion _createOutputSuggestion(
      Output output, int defaultRelevance, Element element) {
    final completion = '(${output.name})';
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element, returnType: output.eventType.toString());
  }

  Element _createPlainAttributeElement(
      String name, int nameOffset, String locationSource, ElementKind kind) {
    final location = Location(locationSource, nameOffset, name.length, 0, 0);
    final flags = Element.makeFlags(
        isAbstract: false, isDeprecated: false, isPrivate: false);
    return Element(kind, name, flags, location: location);
  }

  CompletionSuggestion _createPlainAttributeSuggestions(
          String completion, int defaultRelevance, Element element) =>
      CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
          defaultRelevance, completion, completion.length, 0, false, false,
          element: element);

  Element _createRefValueElement(NavigableString exportAs, ElementKind kind) {
    final name = exportAs.string;
    final location = Location(exportAs.source.fullName,
        exportAs.navigationRange.offset, exportAs.navigationRange.length, 0, 0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags, location: location);
  }

  CompletionSuggestion _createRefValueSuggestion(
      NavigableString exportAs, int defaultRelevance, Element element) {
    final completion = exportAs.string;
    return CompletionSuggestion(CompletionSuggestionKind.INVOCATION,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element);
  }

  Element _createStarAttrElement(AttributeSelector selector, ElementKind kind) {
    final name = '*${selector.nameElement.string}';
    final location = Location(
        selector.nameElement.source.fullName,
        selector.nameElement.navigationRange.offset,
        selector.nameElement.navigationRange.length,
        0,
        0);
    final flags = Element.makeFlags();
    return Element(kind, name, flags, location: location);
  }

  CompletionSuggestion _createStarAttrSuggestion(
      AttributeSelector selector, int defaultRelevance, Element element) {
    final completion = '*${selector.nameElement.string}';
    return CompletionSuggestion(CompletionSuggestionKind.IDENTIFIER,
        defaultRelevance, completion, completion.length, 0, false, false,
        element: element);
  }
}
