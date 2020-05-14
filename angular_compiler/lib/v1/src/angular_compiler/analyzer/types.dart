import 'package:source_gen/source_gen.dart';

/// Most metadata is now in this sub-directory.
const _compilerMetadata = ''
    'package:angular_compiler'
    '/v1/src/metadata';
const _directives = '$_compilerMetadata/directives.dart';
const _diArguments = '$_compilerMetadata/di_arguments.dart';
const _diGeneratedInjector = '$_compilerMetadata/di_generate_injector.dart';
const _diModules = '$_compilerMetadata/di_modules.dart';
const _diProviders = '$_compilerMetadata/di_providers.dart';
const _diTokens = '$_compilerMetadata/di_tokens.dart';
const _typed = '$_compilerMetadata/typed.dart';
const _changeDetectionLink = '$_compilerMetadata/change_detection_link.dart';

/// For legacy reasons some metadata-like classes are not in the compiler.
const _runtimeMetadata = ''
    'package:angular';
const _componentState =
    '$_runtimeMetadata/src/core/change_detection/component_state.dart';

// Class metadata.
const $Directive = TypeChecker.fromUrl('$_directives#Directive');
const $Component = TypeChecker.fromUrl('$_directives#Component');
const $Injectable = TypeChecker.fromUrl('$_diArguments#Injectable');
const $ComponentState = TypeChecker.fromUrl('$_componentState#ComponentState');

// Parameter metadata.
const $Inject = TypeChecker.fromUrl('$_diArguments#Inject');
const $Optional = TypeChecker.fromUrl('$_diArguments#Optional');
const $Self = TypeChecker.fromUrl('$_diArguments#Self');
const $SkipSelf = TypeChecker.fromUrl('$_diArguments#SkipSelf');
const $Host = TypeChecker.fromUrl('$_diArguments#Host');

// Field metadata.
const $ContentChild = TypeChecker.fromUrl('$_directives#ContentChild');
const $ContentChildren = TypeChecker.fromUrl('$_directives#ContentChildren');
const $HostBinding = TypeChecker.fromUrl('$_directives#HostBinding');
const $HostListener = TypeChecker.fromUrl('$_directives#HostListener');
const $Input = TypeChecker.fromUrl('$_directives#Input');
const $Output = TypeChecker.fromUrl('$_directives#Output');
const $Pipe = TypeChecker.fromUrl('$_directives#Pipe');
const $ViewChild = TypeChecker.fromUrl('$_directives#ViewChild');
const $ViewChildren = TypeChecker.fromUrl('$_directives#ViewChildren');

// Class types.
const $GenerateInjector =
    TypeChecker.fromUrl('$_diGeneratedInjector#GenerateInjector');
const $Module = TypeChecker.fromUrl('$_diModules#Module');
const $Provider = TypeChecker.fromUrl('$_diProviders#Provider');
const $OpaqueToken = TypeChecker.fromUrl('$_diTokens#OpaqueToken');
const $MultiToken = TypeChecker.fromUrl('$_diTokens#MultiToken');
const $Typed = TypeChecker.fromUrl('$_typed#Typed');
const $ChangeDetectionLink =
    TypeChecker.fromUrl('$_changeDetectionLink#_ChangeDetectionLink');
