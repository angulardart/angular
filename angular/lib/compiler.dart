/// Starting point to import all compiler APIs.
library angular.compiler;

export 'src/compiler/compiler.dart'
    show
        PLATFORM_DIRECTIVES,
        PLATFORM_PIPES,
        COMPILER_PROVIDERS,
        DirectiveResolver,
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
        CompilePipeMetadata;
export 'src/compiler/template_ast.dart';
export 'src/compiler/view_compiler/parse_utils.dart';
