@TestOn('browser')

import "package:angular2/src/facade/lang.dart"
    show IS_DART, RegExpWrapper, StringWrapper;
import "package:test/test.dart";

import "symbol_inspector/symbol_inspector.dart" show getSymbolsFromLibrary;

// =============================================================================
// =============================================================================
// ============= S T O P   -    S T O P   -  S T O P   -  S T O P  =============
// =============================================================================
// =============================================================================
//
// DO NOT EDIT THIS LIST OF PUBLIC APIS UNLESS YOU GET IT CLEARED BY:
// mhevery, ferhat, or matanl!
//
// =============================================================================
// =============================================================================
var NG_COMMON = [
  "AbstractControl",
  "AbstractControlDirective",
  "AsyncPipe",
  "COMMON_DIRECTIVES",
  "COMMON_PIPES",
  "CORE_DIRECTIVES",
  "CheckboxControlValueAccessor",
  "Control",
  "ControlArray",
  "ControlContainer",
  "ControlGroup",
  "ControlValueAccessor:dart",
  "CurrencyPipe",
  "DatePipe",
  "DecimalPipe",
  "DefaultValueAccessor",
  "FORM_BINDINGS",
  "FORM_DIRECTIVES",
  "FORM_PROVIDERS",
  "Form:dart",
  "FormBuilder",
  "I18nPluralPipe",
  "I18nSelectPipe",
  "JsonPipe",
  "LowerCasePipe",
  "MaxLengthValidator",
  "MinLengthValidator",
  "NG_ASYNC_VALIDATORS",
  "NG_VALIDATORS",
  "NG_VALUE_ACCESSOR",
  "NgClass",
  "NgControl",
  "NgControlGroup",
  "NgControlName",
  "NgControlStatus",
  "NgFor",
  "NgForm",
  "NgFormControl",
  "NgFormModel",
  "NgIf",
  "NgTemplateOutlet",
  "NgModel",
  "NgSelectOption",
  "NgStyle",
  "NgSwitch",
  "NgSwitchWhen",
  "NgSwitchDefault",
  "NumberPipe",
  "ObservableListDiff:dart",
  "ObservableListDiffFactory:dart",
  "PatternValidator",
  "PercentPipe",
  "ReplacePipe",
  "RequiredValidator",
  "SelectControlValueAccessor",
  "SlicePipe",
  "UpperCasePipe",
  "Validator:dart",
  "Validators",
  "RadioButtonState",
  "NgLocalization",
  "NgPlural",
  "NgPluralCase"
];
var NG_COMPILER = [
  "TemplateAst:dart",
  "TemplateAstVisitor:dart",
  "DEFAULT_PACKAGE_URL_PROVIDER",
  "UrlResolver",
  "AttrAst",
  "BoundDirectivePropertyAst",
  "BoundElementPropertyAst",
  "BoundEventAst",
  "BoundTextAst",
  "COMPILER_PROVIDERS",
  "CompileDirectiveMetadata",
  "CompileInjectorModuleMetadata",
  "CompileTemplateMetadata",
  "CompileTypeMetadata",
  "DirectiveAst",
  "ElementAst",
  "EmbeddedTemplateAst",
  "NgContentAst",
  "PLATFORM_DIRECTIVES",
  "PLATFORM_PIPES",
  "PropertyBindingType",
  "SourceModule",
  "TEMPLATE_TRANSFORMS",
  "TextAst",
  "VariableAst",
  "ReferenceAst",
  "XHR",
  "templateVisitAll",
  "CompileDiDependencyMetadata",
  "CompileFactoryMetadata",
  "CompileIdentifierMetadata",
  "CompileMetadataWithIdentifier",
  "CompileMetadataWithType",
  "CompilePipeMetadata",
  "CompileProviderMetadata",
  "CompileQueryMetadata",
  "CompileTokenMetadata",
  "CompilerConfig",
  "RenderTypes",
  "DirectiveResolver",
  "NormalizedComponentWithViewDirectives",
  "OfflineCompiler",
  "PipeResolver",
  "ProviderAst",
  "ProviderAstType",
  "ViewResolver",
  "createOfflineCompileUrlResolver"
];
var NG_CORE = [
  "APP_INITIALIZER",
  "APP_ID",
  "AngularEntrypoint:dart",
  "AbstractProviderError",
  "ApplicationRef",
  "APPLICATION_COMMON_PROVIDERS",
  "Attribute",
  "AttributeMetadata",
  "Binding",
  "Provider",
  "ProviderBuilder",
  "PLATFORM_DIRECTIVES",
  "CollectionChangeRecord",
  "ChangeDetectionStrategy",
  "ChangeDetectorRef",
  "Class:js",
  "ComponentResolver",
  "Component",
  "ComponentMetadata",
  "ComponentRef",
  "ContentChild",
  "ContentChildMetadata",
  "ContentChildren",
  "ContentChildrenMetadata",
  "CyclicDependencyError",
  "PLATFORM_PIPES",
  "DebugNode",
  "DebugElement",
  "ReflectiveDependency",
  "DependencyMetadata",
  "Directive",
  "DirectiveMetadata",
  "InjectorModule",
  "InjectorModuleMetadata",
  "Provides",
  "ProviderPropertyMetadata",
  "DynamicComponentLoader",
  "ElementRef",
  "Output",
  "EmbeddedViewRef",
  "EventEmitter",
  "ExceptionHandler",
  "OutputMetadata",
  "ExpressionChangedAfterItHasBeenCheckedException",
  "Host",
  "HostBinding",
  "HostBindingMetadata",
  "HostListener",
  "HostListenerMetadata",
  "HostMetadata",
  "ComponentFactory",
  "Inject",
  "InjectMetadata",
  "Injectable",
  "InjectableMetadata",
  "Injector",
  "MapInjector",
  "MapInjectorFactory",
  "InjectorFactory",
  "ReflectiveInjector",
  "InstantiationError",
  "InvalidProviderError",
  "IterableDiffers",
  "ReflectiveKey",
  "KeyValueChangeRecord",
  "KeyValueDiffers",
  "NgZone",
  "NgZoneError",
  "NoAnnotationError",
  "NoProviderError",
  "OpaqueToken",
  "Optional",
  "OptionalMetadata",
  "OutOfBoundsError",
  "Pipe",
  "PipeMetadata",
  "PlatformRef",
  "Input",
  "InputMetadata",
  "Query",
  "QueryList",
  "QueryMetadata",
  "Renderer",
  "RootRenderer",
  "RenderComponentType",
  "ResolvedReflectiveBinding:dart",
  "ResolvedReflectiveProvider:dart",
  "ResolvedReflectiveFactory",
  "Self",
  "SelfMetadata",
  "SkipSelf",
  "SkipSelfMetadata",
  "SimpleChange",
  "TemplateRef",
  "Testability",
  "TestabilityRegistry",
  "GetTestability:dart",
  "Type",
  "PACKAGE_ROOT_URL",
  "View:dart",
  /*
  'View.directives:dart',
  'View.encapsulation:dart',
  'View.pipes:dart',
  'View.styleUrls:dart',
  'View.styles:dart',
  'View.template:dart',
  'View.templateUrl:dart',
  */
  "ViewChild",
  "ViewChildMetadata",
  "ViewChildren",
  "ViewChildrenMetadata",
  "ViewContainerRef",
  "ViewEncapsulation",
  "ViewMetadata",
  "ViewQuery",
  "ViewQueryMetadata",
  "WrappedException",
  "WrappedValue",
  "asNativeElements",
  "bind",
  "provide",
  "createNgZone",
  "forwardRef:js",
  "coreBootstrap",
  "coreLoadAndBootstrap",
  "createPlatform",
  "disposePlatform",
  "getPlatform",
  "assertPlatform",
  "resolveForwardRef:js",
  "PLATFORM_COMMON_PROVIDERS",
  "PLATFORM_INITIALIZER",
  "AfterContentChecked:dart",
  "AfterContentInit:dart",
  "AfterViewChecked:dart",
  "AfterViewInit:dart",
  "DoCheck:dart",
  "IterableDifferFactory:dart",
  "IterableDiffer:dart",
  "KeyValueDifferFactory:dart",
  "KeyValueDiffer:dart",
  "OnChanges:dart",
  "OnDestroy:dart",
  "OnInit:dart",
  "PipeTransform:dart",
  "reflector",
  "Stream:dart",
  "GetterFn:dart",
  "MethodFn:dart",
  "NoReflectionCapabilities:dart",
  "PlatformReflectionCapabilities:dart",
  "ReflectionInfo",
  "Reflector",
  "SetterFn:dart",
  "ViewRef",
  "TrackByFn:dart"
];
var NG_INSTRUMENTATION = [
  "wtfCreateScope",
  "wtfEndTimeRange",
  "wtfLeave",
  "WtfScopeFn:dart",
  "wtfStartTimeRange"
];
var NG_PLATFORM_BROWSER = [
  "AngularEntrypoint:dart",
  "BROWSER_APP_PROVIDERS",
  "BROWSER_PROVIDERS",
  "BROWSER_SANITIZATION_PROVIDERS",
  'SanitizationService',
  'TemplateSecurityContext',
  "BrowserDomAdapter",
  "By",
  "CACHED_TEMPLATE_PROVIDER",
  "DOCUMENT",
  "ELEMENT_PROBE_PROVIDERS",
  "ELEMENT_PROBE_PROVIDERS_PROD_MODE",
  "Title",
  "bootstrap",
  "browserPlatform",
  "disableDebugTools",
  "enableDebugTools",
  "inspectNativeElement"
];
var NG_PLATFORM_COMMON = [
  "APP_BASE_HREF",
  "HashLocationStrategy",
  "Location",
  "LocationStrategy",
  "PathLocationStrategy",
  "PlatformLocation",
  "UrlChangeEvent:dart",
  "UrlChangeListener:dart"
];
var NG_UPGRADE = ["UpgradeAdapter", "UpgradeAdapterRef"];
var NG_API = {
  "ngCommon": NG_COMMON,
  "ngCompiler": NG_COMPILER,
  "ngCore": NG_CORE,
  "ngInstrumentation": NG_INSTRUMENTATION,
  "ngPlatformBrowser": NG_PLATFORM_BROWSER,
  "ngPlatformCommon": NG_PLATFORM_COMMON,
  "ngUpgrade": NG_UPGRADE
};

main() {
  /**
   var x = getSymbolsFromLibrary('ng');
   x.sort();
   var parts = [];
   x.forEach((i) => parts.push(`'${i'`));
  print(`[ ${parts.join(',
  ')} ]`);
   */
  group("public API", () {
    var barrelList = [
      "ngCommon",
      "ngCompiler",
      "ngCore",
      "ngInstrumentation",
      "ngPlatformBrowser",
      "ngPlatformCommon",
      "ngUpgrade"
    ];
    if (IS_DART) {
      barrelList = barrelList.where((b) => !identical(b, "ngUpgrade")).toList();
    }
    barrelList.forEach((mod) {
      // Dom Events are merged into DomAdapter in Dart
      if (IS_DART && identical(mod, "ngPlatformDomEvent")) return;
      test('''should fail if public API for ${ mod} has changed''', () {
        var symbols = getSymbolsFromLibrary(mod);
        expect(diff(symbols, NG_API[mod]), []);
      });
    });
  });
}

List<String> diff(List<String> actual, List<String> expected) {
  actual.sort(compareIgnoreLang);
  expected.sort(compareIgnoreLang);
  var mode = IS_DART ? "dart" : "js";
  var missing = actual
      .where((i) =>
          expected.indexOf(i) < 0 && expected.indexOf('''${ i}:${ mode}''') < 0)
      .toList()
      .map((s) => '''+${ s}''')
      .toList();
  var extra = expected
      .where(
          (i) => shouldIgnore(i) ? false : (actual.indexOf(stripLang(i)) < 0))
      .toList()
      .map((s) => '''-${ s}''')
      .toList();
  return <String>[]..addAll(missing)..addAll(extra);
}

bool shouldIgnore(String expected) {
  var isDart = RegExpWrapper.create("\\:dart\$");
  var isJs = RegExpWrapper.create("\\:js\$");
  return IS_DART
      ? RegExpWrapper.test(isJs, expected)
      : RegExpWrapper.test(isDart, expected);
}

int compareIgnoreLang(String a, String b) {
  return StringWrapper.compare(stripLang(a), stripLang(b));
}

String stripLang(String text) {
  var index = text.indexOf(":");
  return (index >= 0) ? text.substring(0, index) : text;
}
