import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/source_gen/common/url_resolver.dart';
import 'package:build/build.dart';

CompileTypeMetadata getType(Element element, AssetId inputId) {
  return new CompileTypeMetadata(
      name: element.name,
      moduleUrl: element?.source?.uri?.toString() ?? toAssetUri(inputId));
}
