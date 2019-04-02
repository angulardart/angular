import 'package:analyzer/src/summary/base.dart' as base;
import 'package:analyzer/src/summary/base.dart' show Id, TopLevel;

import 'format.dart' as generated;

@TopLevel('APLD')
abstract class LinkedDartSummary extends base.SummaryClass {
  factory LinkedDartSummary.fromBuffer(List<int> buffer) =>
      generated.readLinkedDartSummary(buffer);

  @Id(0)
  List<SummarizedAnalysisError> get errors;

  @Id(3)
  bool get hasDartTemplates;

  @Id(2)
  List<String> get referencedDartFiles;

  @Id(1)
  List<String> get referencedHtmlFiles;
}

@TopLevel('APLH')
abstract class LinkedHtmlSummary extends base.SummaryClass {
  factory LinkedHtmlSummary.fromBuffer(List<int> buffer) =>
      generated.readLinkedHtmlSummary(buffer);

  @Id(0)
  List<SummarizedAnalysisError> get errors;
  @Id(1)
  List<SummarizedAnalysisErrorFromPath> get errorsFromPath;
}

@TopLevel('APdl')
abstract class PackageBundle extends base.SummaryClass {
  factory PackageBundle.fromBuffer(List<int> buffer) =>
      generated.readPackageBundle(buffer);

  @Id(0)
  List<UnlinkedDartSummary> get unlinkedDartSummary;
}

abstract class SummarizedAnalysisError extends base.SummaryClass {
  @Id(2)
  String get correction;
  @Id(0)
  String get errorCode;
  @Id(4)
  int get length;
  @Id(1)
  String get message;
  @Id(3)
  int get offset;
}

abstract class SummarizedAnalysisErrorFromPath extends base.SummaryClass {
  @Id(1)
  String get classname;
  @Id(2)
  SummarizedAnalysisError get originalError;
  @Id(0)
  String get path;
}

abstract class SummarizedBindable extends base.SummaryClass {
  @Id(0)
  String get name;
  @Id(1)
  int get nameOffset;
  @Id(2)
  String get propName;
  @Id(3)
  int get propNameOffset;
}

abstract class SummarizedClassAnnotations extends base.SummaryClass {
  @Id(0)
  String get className;
  @Id(3)
  List<SummarizedContentChildField> get contentChildFields;
  @Id(4)
  List<SummarizedContentChildField> get contentChildrenFields;
  @Id(1)
  List<SummarizedBindable> get inputs;
  @Id(2)
  List<SummarizedBindable> get outputs;
}

abstract class SummarizedContentChildField extends base.SummaryClass {
  @Id(0)
  String get fieldName;
  @Id(2)
  int get nameLength;
  @Id(1)
  int get nameOffset;
  @Id(4)
  int get typeLength;
  @Id(3)
  int get typeOffset;
}

abstract class SummarizedDirective extends base.SummaryClass {
  @Id(0)
  SummarizedClassAnnotations get classAnnotations;
  @Id(18)
  int get constDirectiveStrategyLength;
  @Id(17)
  int get constDirectiveStrategyOffset;
  @Id(5)
  String get exportAs;
  @Id(6)
  int get exportAsOffset;
  @Id(15)
  List<SummarizedExportedIdentifier> get exports;
  @Id(1)
  String get functionName;
  @Id(2)
  bool get isComponent;
  @Id(12)
  List<SummarizedNgContent> get ngContents;
  @Id(16)
  List<SummarizedPipesUse> get pipesUse;
  @Id(4)
  int get selectorOffset;
  @Id(3)
  String get selectorStr;
  @Id(14)
  List<SummarizedDirectiveUse> get subdirectives;
  @Id(11)
  int get templateOffset;
  @Id(10)
  String get templateText;
  @Id(7)
  String get templateUrl;
  @Id(9)
  int get templateUrlLength;
  @Id(8)
  int get templateUrlOffset;
  @Id(13)
  bool get usesArrayOfDirectiveReferencesStrategy;
}

abstract class SummarizedDirectiveUse extends base.SummaryClass {
  @Id(3)
  int get length;
  @Id(0)
  String get name;
  @Id(2)
  int get offset;
  @Id(1)
  String get prefix;
}

abstract class SummarizedExportedIdentifier extends base.SummaryClass {
  @Id(3)
  int get length;
  @Id(0)
  String get name;
  @Id(2)
  int get offset;
  @Id(1)
  String get prefix;
}

abstract class SummarizedNgContent extends base.SummaryClass {
  @Id(1)
  int get length;
  @Id(0)
  int get offset;
  @Id(3)
  int get selectorOffset;
  @Id(2)
  String get selectorStr;
}

abstract class SummarizedPipe extends base.SummaryClass {
  @Id(3)
  String get decoratedClassName;
  @Id(2)
  bool get isPure;
  @Id(0)
  String get pipeName;
  @Id(1)
  int get pipeNameOffset;
}

abstract class SummarizedPipesUse extends base.SummaryClass {
  @Id(3)
  int get length;
  @Id(0)
  String get name;
  @Id(2)
  int get offset;
  @Id(1)
  String get prefix;
}

@TopLevel('APUD')
abstract class UnlinkedDartSummary extends base.SummaryClass {
  factory UnlinkedDartSummary.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedDartSummary(buffer);

  @Id(1)
  List<SummarizedClassAnnotations> get annotatedClasses;
  @Id(0)
  List<SummarizedDirective> get directiveSummaries;
  @Id(2)
  List<SummarizedAnalysisError> get errors;
  @Id(3)
  List<SummarizedPipe> get pipeSummaries;
}

@TopLevel('APUH')
abstract class UnlinkedHtmlSummary extends base.SummaryClass {
  factory UnlinkedHtmlSummary.fromBuffer(List<int> buffer) =>
      generated.readUnlinkedHtmlSummary(buffer);

  @Id(0)
  List<SummarizedNgContent> get ngContents;
}
