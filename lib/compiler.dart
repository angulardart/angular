/// Starting point to import all compiler APIs.
library angular2.compiler;

export "package:angular2/src/compiler/compiler.dart"
    show
        PLATFORM_DIRECTIVES,
        PLATFORM_PIPES,
        COMPILER_PROVIDERS,
        CompilerConfig,
        RenderTypes,
        UrlResolver,
        DEFAULT_PACKAGE_URL_PROVIDER,
        createOfflineCompileUrlResolver,
        XHR,
        ViewResolver,
        DirectiveResolver,
        PipeResolver,
        SourceModule,
        NormalizedComponentWithViewDirectives,
        OfflineCompiler,
        CompileMetadataWithIdentifier,
        CompileMetadataWithType,
        CompileIdentifierMetadata,
        CompileDiDependencyMetadata,
        CompileProviderMetadata,
        CompileFactoryMetadata,
        CompileTokenMetadata,
        CompileTypeMetadata,
        CompileQueryMetadata,
        CompileTemplateMetadata,
        CompileDirectiveMetadata,
        CompileInjectorModuleMetadata,
        CompilePipeMetadata;
export "package:angular2/src/compiler/template_ast.dart";
