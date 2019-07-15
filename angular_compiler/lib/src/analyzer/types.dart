import 'package:source_gen/source_gen.dart';

// Where to find types provided by AngularDart.
const _angular = 'package:angular';
const _componentState =
    '$_angular/src/core/change_detection/component_state.dart';
const _meta = '$_angular/src/core/metadata.dart';
const _di = '$_angular/src/core/di/decorators.dart';
const _injector = '$_angular/src/di/injector/injector.dart';
const _module = '$_angular/src/di/module.dart';
const _provider = '$_angular/src/di/providers.dart';
const _token = '$_angular/src/core/di/opaque_token.dart';
const _typed = '$_angular/src/core/metadata/typed.dart';
const _changeDetectionLink =
    '$_angular/src/core/metadata/change_detection_link.dart';

// Class metadata.
const $Directive = TypeChecker.fromUrl('$_meta#Directive');
const $Component = TypeChecker.fromUrl('$_meta#Component');
const $Injectable = TypeChecker.fromUrl('$_di#Injectable');
const $ComponentState = TypeChecker.fromUrl('$_componentState#ComponentState');

// Parameter metadata.
const $Inject = TypeChecker.fromUrl('$_di#Inject');
const $Optional = TypeChecker.fromUrl('$_di#Optional');
const $Self = TypeChecker.fromUrl('$_di#Self');
const $SkipSelf = TypeChecker.fromUrl('$_di#SkipSelf');
const $Host = TypeChecker.fromUrl('$_di#Host');

// Field metadata.
const $HostBinding = TypeChecker.fromUrl('$_meta#HostBinding');
const $HostListener = TypeChecker.fromUrl('$_meta#HostListener');

// Class types.
const $GenerateInjector = TypeChecker.fromUrl(
  '$_injector#GenerateInjector',
);
const $Module = TypeChecker.fromUrl('$_module#Module');
const $Provider = TypeChecker.fromUrl('$_provider#Provider');
const $OpaqueToken = TypeChecker.fromUrl('$_token#OpaqueToken');
const $MultiToken = TypeChecker.fromUrl('$_token#MultiToken');
const $Typed = TypeChecker.fromUrl('$_typed#Typed');
const $ChangeDetectionLink =
    TypeChecker.fromUrl('$_changeDetectionLink#_ChangeDetectionLink');
