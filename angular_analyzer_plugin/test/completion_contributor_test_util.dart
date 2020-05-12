import 'dart:async';

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol
    show ElementKind;
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide Element, ElementKind;
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_completion_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_inherited_reference_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_type_member_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_offset_length_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:test/test.dart';

import 'angular_driver_base.dart';

int suggestionComparator(CompletionSuggestion s1, CompletionSuggestion s2) {
  final c1 = s1.completion.toLowerCase();
  final c2 = s2.completion.toLowerCase();
  return c1.compareTo(c2);
}

abstract class AbstractCompletionContributorTest
    extends BaseCompletionContributorTest {
  List<CompletionContributor> contributors;
  CompletionCollectorImpl collector;

  @override
  Future computeSuggestions([int times = 200]) async {
    final templates = await angularDriver.computeTemplatesForFile(testFile);
    final standardHtml = await angularDriver.buildStandardHtml();
    final angularCompletionRequest = AngularCompletionRequest(
        completionOffset, testFile, resourceProvider, templates, standardHtml);
    final collector = CompletionCollectorImpl();

    // Request completions
    for (final contributor in contributors) {
      await contributor.computeSuggestions(angularCompletionRequest, collector);
    }
    if (!collector.offsetIsSet) {
      collector
        ..offset = angularCompletionRequest.offset
        ..length = 0;
    }
    suggestions = collector.suggestions;
    replacementOffset = collector.offset;
    replacementLength = collector.length;
    expect(suggestions, isNotNull, reason: 'expected suggestions');
  }

  List<CompletionContributor> createContributors() => <CompletionContributor>[
        AngularCompletionContributor(),
        AngularInheritedReferenceContributor(),
        AngularTypeMemberContributor(),
        AngularOffsetLengthContributor(),
      ];

  /// Resolve the external template of a view declared in the [dartSource].
  Future resolveSingleTemplate(Source dartSource) async {
    final result = await angularDriver.requestDartResult(dartSource.fullName);
    for (var d in result.directives) {
      if (d is Component && d.templateUrlSource != null) {
        final htmlPath = d.templateUrlSource.fullName;
        await angularDriver.requestHtmlResult(htmlPath);
      }
    }
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    contributors = createContributors();
  }
}

abstract class BaseCompletionContributorTest extends AngularDriverTestBase {
  String testFile;
  Source testSource;
  int completionOffset;
  int replacementOffset;
  int replacementLength;
  List<CompletionSuggestion> suggestions;

  void addTestSource(String content) {
    expect(completionOffset, isNull, reason: 'Call addTestUnit exactly once');
    completionOffset = content.indexOf('^');
    expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
    final nextOffset = content.indexOf('^', completionOffset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');
    // ignore: parameter_assignments, prefer_interpolation_to_compose_strings
    content = content.substring(0, completionOffset) +
        content.substring(completionOffset + 1);
    testSource = newSource(testFile, content);
  }

  void assertHasNoParameterInfo(final suggestion) {
    expect(suggestion.parameterNames, isNull);
    expect(suggestion.parameterTypes, isNull);
    expect(suggestion.requiredParameterCount, isNull);
    expect(suggestion.hasNamedParameters, isNull);
  }

  void assertHasParameterInfo(final suggestion) {
    expect(suggestion.parameterNames, isNotNull);
    expect(suggestion.parameterTypes, isNotNull);
    expect(suggestion.parameterNames.length, suggestion.parameterTypes.length);
    expect(suggestion.requiredParameterCount,
        lessThanOrEqualTo(suggestion.parameterNames.length));
    expect(suggestion.hasNamedParameters, isNotNull);
  }

  void assertNoSuggestions({CompletionSuggestionKind kind}) {
    if (kind == null) {
      if (suggestions.isNotEmpty) {
        failedCompletion('Expected no suggestions', suggestions);
      }
      return;
    }
    final suggestion = suggestions.firstWhere((final cs) => cs.kind == kind,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  void assertNotSuggested(String completion) {
    final suggestion = suggestions.firstWhere(
        (final cs) => cs.completion == completion,
        orElse: () => null);
    if (suggestion != null) {
      failedCompletion('did not expect completion: $completion\n  $suggestion');
    }
  }

  CompletionSuggestion assertSuggest(String completion,
      {CompletionSuggestionKind csKind = CompletionSuggestionKind.INVOCATION,
      int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      protocol.ElementKind elemKind,
      bool isDeprecated = false,
      bool isPotential = false,
      String elemFile,
      int elemOffset,
      final paramName,
      final paramType}) {
    final cs =
        getSuggest(completion: completion, csKind: csKind, elemKind: elemKind);
    if (cs == null) {
      failedCompletion('expected $completion $csKind $elemKind', suggestions);
    }
    expect(cs.kind, equals(csKind));
    if (isDeprecated) {
      expect(cs.relevance, equals(DART_RELEVANCE_LOW));
    } else {
      expect(cs.relevance, equals(relevance), reason: completion);
    }
    expect(cs.selectionOffset, equals(completion.length));
    expect(cs.selectionLength, equals(0));
    expect(cs.isDeprecated, equals(isDeprecated));
    expect(cs.isPotential, equals(isPotential));
    if (cs.element != null) {
      expect(cs.element.location, isNotNull);
      expect(cs.element.location.file, isNotNull);
      expect(cs.element.location.offset, isNotNull);
      expect(cs.element.location.length, isNotNull);
      expect(cs.element.location.startColumn, isNotNull);
      expect(cs.element.location.startLine, isNotNull);
    }
    if (elemFile != null) {
      expect(cs.element.location.file, elemFile);
    }
    if (elemOffset != null) {
      expect(cs.element.location.offset, elemOffset);
    }
    if (paramName != null) {
      expect(cs.parameterName, paramName);
    }
    if (paramType != null) {
      expect(cs.parameterType, paramType);
    }
    return cs;
  }

  CompletionSuggestion assertSuggestClass(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      String elemFile,
      String elemName,
      int elemOffset}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated,
        elemFile: elemFile,
        elemOffset: elemOffset);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(elemName ?? name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestClassTypeAlias(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    final cs = assertSuggest(name, csKind: kind, relevance: relevance);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestConstructor(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      int elemOffset}) {
    final cs = assertSuggest(name,
        relevance: relevance, importUri: importUri, elemOffset: elemOffset);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CONSTRUCTOR));
    final index = name.indexOf('.');
    expect(element.name, index >= 0 ? name.substring(index + 1) : '');
    return cs;
  }

  CompletionSuggestion assertSuggestEnum(String completion,
      {bool isDeprecated = false}) {
    final suggestion = assertSuggest(completion, isDeprecated: isDeprecated);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, protocol.ElementKind.ENUM);
    return suggestion;
  }

  CompletionSuggestion assertSuggestEnumConst(String completion,
      {int relevance = DART_RELEVANCE_DEFAULT, bool isDeprecated = false}) {
    final suggestion = assertSuggest(completion,
        relevance: relevance, isDeprecated: isDeprecated);
    expect(suggestion.completion, completion);
    expect(suggestion.isDeprecated, isDeprecated);
    expect(suggestion.element.kind, protocol.ElementKind.ENUM_CONSTANT);
    return suggestion;
  }

  CompletionSuggestion assertSuggestField(String name, String type,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        elemKind: protocol.ElementKind.FIELD,
        isDeprecated: isDeprecated);
    // The returnType represents the type of a field
    expect(cs.returnType, type ?? 'dynamic');
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FIELD));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    // The returnType represents the type of a field
    expect(element.returnType, type ?? 'dynamic');
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunction(String name, String returnType,
      {CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      String elementName}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else {
      expect(cs.returnType, 'dynamic');
    }
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION));
    expect(element.name, equals(elementName ?? name));
    expect(element.isDeprecated, equals(isDeprecated));
    final param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    if (returnType != null) {
      expect(element.returnType, returnType);
    } else {
      expect(element.returnType, 'dynamic');
    }
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestFunctionTypeAlias(
      String name, String returnType,
      {bool isDeprecated = false,
      int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String importUri}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else {
      expect(cs.returnType, 'dynamic');
    }
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.FUNCTION_TYPE_ALIAS));
    expect(element.name, equals(name));
    expect(element.isDeprecated, equals(isDeprecated));
    // TODO (danrubel) Determine why params are null
    //    final param = element.parameters;
    //    expect(param, isNotNull);
    //    expect(param[0], equals('('));
    //    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, equals(returnType ?? 'dynamic'));
    // TODO (danrubel) Determine why param info is missing
    //    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestGetter(String name, String returnType,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false,
      String elementName}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        elemKind: protocol.ElementKind.GETTER,
        isDeprecated: isDeprecated);
    expect(cs.returnType, returnType ?? 'dynamic');
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.GETTER));
    expect(element.name, equals(elementName ?? name));
    expect(element.parameters, isNull);
    expect(element.returnType, equals(returnType ?? 'dynamic'));
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestLabel(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String returnType = 'dynamic'}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        elemKind: protocol.ElementKind.LABEL);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LABEL));
    expect(element.name, equals(name));
    if (element.returnType != null) {
      expect(element.returnType, returnType);
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestLibrary(String name,
      {int relevance = DART_RELEVANCE_DEFAULT}) {
    final cs = assertSuggest(name,
        csKind: CompletionSuggestionKind.IDENTIFIER, relevance: relevance);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LIBRARY));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestLocalVar(String name, String returnType,
      {int relevance = DART_RELEVANCE_LOCAL_VARIABLE,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String importUri}) {
    final cs = assertSuggest(name,
        csKind: kind, relevance: relevance, importUri: importUri);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else {
      expect(cs.returnType, 'dynamic');
    }
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.LOCAL_VARIABLE));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    if (returnType != null) {
      expect(element.returnType, returnType);
    } else {
      expect(element.returnType, 'dynamic');
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestMethod(
      String name, String declaringType, String returnType,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      bool isDeprecated = false}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    expect(cs.declaringType, equals(declaringType));
    expect(cs.returnType, returnType ?? 'dynamic');
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.METHOD));
    expect(element.name, equals(name));
    final param = element.parameters;
    expect(param, isNotNull);
    expect(param[0], equals('('));
    expect(param[param.length - 1], equals(')'));
    expect(element.returnType, returnType ?? 'dynamic');
    assertHasParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestName(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.IDENTIFIER,
      bool isDeprecated = false}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        isDeprecated: isDeprecated);
    expect(cs.completion, equals(name));
    expect(cs.element, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestSetter(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String returnType = 'dynamic'}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        elemKind: protocol.ElementKind.SETTER);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.SETTER));
    expect(element.name, equals(name));
    // TODO (danrubel) assert setter param
    //expect(element.parameters, isNull);
    // TODO (danrubel) it would be better if this was always null
    if (element.returnType != null) {
      expect(element.returnType, returnType);
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestStar(String name,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.IDENTIFIER}) {
    final cs = assertSuggest(name, csKind: kind, relevance: relevance);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.CLASS));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    expect(element.returnType, isNull);
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestTemplateInput(String name,
      {String elementName,
      int relevance = DART_RELEVANCE_DEFAULT,
      String importUri,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION}) {
    final cs = assertSuggest(name,
        csKind: kind,
        relevance: relevance,
        importUri: importUri,
        elemKind: protocol.ElementKind.SETTER);
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.SETTER));
    expect(element.name, equals(elementName));
    if (element.returnType != null) {
      expect(element.returnType, 'dynamic');
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  CompletionSuggestion assertSuggestTopLevelVar(String name, String returnType,
      {int relevance = DART_RELEVANCE_DEFAULT,
      CompletionSuggestionKind kind = CompletionSuggestionKind.INVOCATION,
      String importUri}) {
    final cs = assertSuggest(name,
        csKind: kind, relevance: relevance, importUri: importUri);
    if (returnType != null) {
      expect(cs.returnType, returnType);
    } else {
      expect(cs.returnType, 'dynamic');
    }
    final element = cs.element;
    expect(element, isNotNull);
    expect(element.kind, equals(protocol.ElementKind.TOP_LEVEL_VARIABLE));
    expect(element.name, equals(name));
    expect(element.parameters, isNull);
    if (returnType != null) {
      expect(element.returnType, returnType);
    } else {
      expect(element.returnType, 'dynamic');
    }
    assertHasNoParameterInfo(cs);
    return cs;
  }

  Future computeSuggestions([int times = 200]);

  void failedCompletion(String message,
      [Iterable<CompletionSuggestion> completions]) {
    final sb = StringBuffer(message);
    if (completions != null) {
      sb.write('\n  found');
      completions.toList()
        ..sort(suggestionComparator)
        ..forEach((final suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
    }
    fail(sb.toString());
  }

  CompletionSuggestion getSuggest(
      {String completion,
      CompletionSuggestionKind csKind,
      protocol.ElementKind elemKind}) {
    CompletionSuggestion cs;
    if (suggestions != null) {
      suggestions.forEach((s) {
        if (completion != null && completion != s.completion) {
          return;
        }
        if (csKind != null && csKind != s.kind) {
          return;
        }
        if (elemKind != null) {
          final element = s.element;
          if (element == null || elemKind != element.kind) {
            return;
          }
        }
        if (cs == null) {
          cs = s;
        } else {
          failedCompletion('expected exactly one $cs',
              suggestions.where((s) => s.completion == completion));
        }
      });
    }
    return cs;
  }
}
