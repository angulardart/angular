import 'package:analyzer/dart/element/element.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';
import 'package:angular_analyzer_plugin/src/link/top_level_linker.dart';

export 'package:angular_analyzer_plugin/src/link/eager_linker.dart';
export 'package:angular_analyzer_plugin/src/link/lazy_linker.dart';

/// Link a [Pipe] with the specified [Linker] from its summary & element.
Pipe linkPipe(List<SummarizedPipe> pipeSummaries, ClassElement element,
    TopLevelLinker linker) {
  for (final sum in pipeSummaries) {
    if (sum.decoratedClassName == element.name) {
      return linker.pipe(sum, element);
    }
  }

  return null;
}

/// Link [Pipe]s with the specified [Linker] from a summary & compilation unit.
List<Pipe> linkPipes(List<SummarizedPipe> pipeSummaries,
    CompilationUnitElement compilationUnitElement, TopLevelLinker linker) {
  final pipes = <Pipe>[];

  for (final pipeSum in pipeSummaries) {
    final classElem =
        compilationUnitElement.getType(pipeSum.decoratedClassName);
    pipes.add(linker.pipe(pipeSum, classElem));
  }

  return pipes;
}

/// Link [TopLevel] with the [Linker] from its summary & element.
TopLevel linkTopLevel(
    UnlinkedDartSummary unlinked, Element element, TopLevelLinker linker) {
  if (element is ClassElement) {
    for (final sum in unlinked.directiveSummaries) {
      if (sum.classAnnotations?.className == element.name) {
        return sum.isComponent
            ? linker.component(sum, element)
            : linker.directive(sum, element);
      }
    }

    for (final sum in unlinked.annotatedClasses) {
      if (sum.className == element.name) {
        return linker.annotatedClass(sum, element);
      }
    }
  } else if (element is FunctionElement) {
    for (final sum in unlinked.directiveSummaries) {
      if (sum.functionName == element.name) {
        return linker.functionalDirective(sum, element);
      }
    }
  }

  return null;
}

/// Link [TopLevel]s with the [Linker] from summary & compilation unit.
List<TopLevel> linkTopLevels(UnlinkedDartSummary unlinked,
        CompilationUnitElement compilationUnitElement, TopLevelLinker linker) =>
    unlinked.directiveSummaries.map<TopLevel>((sum) {
      if (sum.isComponent) {
        return linker.component(sum,
            compilationUnitElement.getType(sum.classAnnotations.className));
      } else if (sum.functionName != "") {
        return linker.functionalDirective(
            sum,
            compilationUnitElement.functions
                .singleWhere((f) => f.name == sum.functionName));
      } else {
        return linker.directive(sum,
            compilationUnitElement.getType(sum.classAnnotations.className));
      }
    }).toList()
      ..addAll(unlinked.annotatedClasses.map((sum) => linker.annotatedClass(
          sum, compilationUnitElement.getType(sum.className))));
