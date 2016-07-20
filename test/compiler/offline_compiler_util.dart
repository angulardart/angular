library angular2.test.compiler.offline_compiler_util;

import "dart:async";

import "package:angular2/src/compiler/compile_metadata.dart"
    show CompileDirectiveMetadata, CompileTypeMetadata, CompileTemplateMetadata;
import "package:angular2/src/compiler/config.dart" show CompilerConfig;
import "package:angular2/src/compiler/directive_normalizer.dart"
    show DirectiveNormalizer;
import "package:angular2/src/compiler/expression_parser/lexer.dart" show Lexer;
import "package:angular2/src/compiler/expression_parser/parser.dart"
    show Parser;
import "package:angular2/src/compiler/html_parser.dart" show HtmlParser;
import "package:angular2/src/compiler/offline_compiler.dart"
    show OfflineCompiler, NormalizedComponentWithViewDirectives;
import "package:angular2/src/compiler/output/abstract_emitter.dart"
    show OutputEmitter;
import "package:angular2/src/compiler/style_compiler.dart" show StyleCompiler;
import "package:angular2/src/compiler/template_parser.dart" show TemplateParser;
import "package:angular2/src/compiler/url_resolver.dart"
    show createOfflineCompileUrlResolver;
import "package:angular2/src/compiler/util.dart" show MODULE_SUFFIX;
import "package:angular2/src/compiler/view_compiler/injector_compiler.dart"
    show InjectorCompiler;
import "package:angular2/src/compiler/view_compiler/view_compiler.dart"
    show ViewCompiler;
import "package:angular2/src/compiler/xhr_mock.dart" show MockXHR;
import "package:angular2/src/core/console.dart" show Console;

import "schema_registry_mock.dart" show MockSchemaRegistry;

class CompA {
  String user;
}

var THIS_MODULE_PATH = '''asset:angular2/test/compiler''';
var THIS_MODULE_URL =
    '''${ THIS_MODULE_PATH}/offline_compiler_util${ MODULE_SUFFIX}''';
var compAMetadata = CompileDirectiveMetadata.create(
    isComponent: true,
    selector: "comp-a",
    type: new CompileTypeMetadata(
        name: "CompA", moduleUrl: THIS_MODULE_URL, runtime: CompA, diDeps: []),
    template: new CompileTemplateMetadata(
        templateUrl: "./offline_compiler_compa.html",
        styles: [".redStyle { color: red; }"],
        styleUrls: ["./offline_compiler_compa.css"]));
OfflineCompiler _createOfflineCompiler(MockXHR xhr, OutputEmitter emitter) {
  var urlResolver = createOfflineCompileUrlResolver();
  xhr.when('''${ THIS_MODULE_PATH}/offline_compiler_compa.html''',
      "Hello World {{user}}!");
  var htmlParser = new HtmlParser();
  var normalizer = new DirectiveNormalizer(xhr, urlResolver, htmlParser);
  return new OfflineCompiler(
      normalizer,
      new TemplateParser(new Parser(new Lexer()),
          new MockSchemaRegistry({}, {}), htmlParser, new Console(), []),
      new StyleCompiler(urlResolver),
      new ViewCompiler(new CompilerConfig(true, true, true)),
      new InjectorCompiler(),
      emitter);
}

Future<String> compileComp(
    OutputEmitter emitter, CompileDirectiveMetadata comp) {
  var xhr = new MockXHR();
  var compiler = _createOfflineCompiler(xhr, emitter);
  var result = compiler.normalizeDirectiveMetadata(comp).then((normComp) {
    return compiler.compile(
        [new NormalizedComponentWithViewDirectives(normComp, [], [])],
        []).source;
  });
  xhr.flush();
  return result;
}
