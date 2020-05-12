/// This library exists for vm targets, which cannot depend on angular.dart.
/// Other targets should use angular.dart instead.
/// @nodoc

export 'package:angular_compiler/v1/src/metadata.dart'
    show Component, Directive, Input, Output, Pipe;
export 'src/core/change_detection/pipe_transform.dart';
export 'src/core/di.dart';
export 'src/core/zone/ng_zone.dart' show NgZone, NgZoneError;
