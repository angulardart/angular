import 'package:analyzer/src/generated/source.dart';

/// Represents an Html element that can be matched by a selector.
abstract class ElementView {
  Map<String, SourceRange> get attributeNameSpans;
  Map<String, String> get attributes;
  Map<String, SourceRange> get attributeValueSpans;
  SourceRange get closingNameSpan;
  SourceRange get closingSpan;
  String get localName;
  SourceRange get openingNameSpan;
  SourceRange get openingSpan;
}
