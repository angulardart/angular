import 'package:analyzer/dart/element/element.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';

/// Interface to look up [TopLevel]s by the dart [Element] model.
abstract class DirectiveProvider {
  TopLevel getAngularTopLevel(Element element);
  List<NgContent> getHtmlNgContent(String path);
  Pipe getPipe(ClassElement element);
}
