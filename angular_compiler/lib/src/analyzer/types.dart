import 'package:source_gen/source_gen.dart';

// Where to find types provided by AngularDart.
const _angular = 'package:angular';
const _meta = '$_angular/src/core/metadata.dart';
const _di = '$_angular/src/core/di/decorators.dart';
const _injector = '$_angular/src/di/injector/injector.dart';
const _module = '$_angular/src/di/module.dart';
const _provider = '$_angular/src/di/providers.dart';
const _token = '$_angular/src/core/di/opaque_token.dart';
const _typed = '$_angular/src/core/metadata/typed.dart';

// Class metadata.
const $Directive = TypeChecker.fromUrl('$_meta#Directive');
const $Component = TypeChecker.fromUrl('$_meta#Component');
const $Pipe = TypeChecker.fromUrl('$_meta#Pipe');
const $Injectable = TypeChecker.fromUrl('$_di#Injectable');

// Parameter metadata.
const $Attribute = TypeChecker.fromUrl('$_meta#Attribute');
const $Inject = TypeChecker.fromUrl('$_di#Inject');
const $Optional = TypeChecker.fromUrl('$_di#Optional');
const $Self = TypeChecker.fromUrl('$_di#Self');
const $SkipSelf = TypeChecker.fromUrl('$_di#SkipSelf');
const $Host = TypeChecker.fromUrl('$_di#Host');

// Field metadata.
const $ContentChildren = TypeChecker.fromUrl('$_meta#ContentChildren');
const $ContentChild = TypeChecker.fromUrl('$_meta#ContentChild');
const $ViewChildren = TypeChecker.fromUrl('$_meta#ViewChildren');
const $ViewChild = TypeChecker.fromUrl('$_meta#ViewChild');
const $Input = TypeChecker.fromUrl('$_meta#Input');
const $Output = TypeChecker.fromUrl('$_meta#Output');
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
