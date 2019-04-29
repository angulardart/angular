import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// The implementation of [ElementView] using [AttributeInfo]s.
class ElementViewImpl implements ElementView {
  @override
  final attributeNameSpans = <String, SourceRange>{};

  @override
  final attributeValueSpans = <String, SourceRange>{};

  @override
  final attributes = <String, String>{};

  @override
  SourceRange closingSpan;

  @override
  SourceRange closingNameSpan;

  @override
  String localName;

  @override
  SourceRange openingSpan;

  @override
  SourceRange openingNameSpan;

  ElementViewImpl(List<AttributeInfo> attributeInfoList,
      {ElementInfo element, String elementName}) {
    for (final attribute in attributeInfoList) {
      if (attribute is TemplateAttribute) {
        continue;
      }
      final name = attribute.name;
      attributeNameSpans[name] =
          SourceRange(attribute.nameOffset, attribute.name.length);
      if (attribute.value != null) {
        attributeValueSpans[name] =
            SourceRange(attribute.valueOffset, attribute.valueLength);
      }
      attributes[name] = attribute.value;
    }
    if (element != null) {
      localName = element.localName;
      openingSpan = element.openingSpan;
      closingSpan = element.closingSpan;
      openingNameSpan = element.openingNameSpan;
      closingNameSpan = element.closingNameSpan;
    } else if (elementName != null) {
      localName = elementName;
    }
  }
}
