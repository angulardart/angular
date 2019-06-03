/// This library exists for vm targets, which cannot depend on angular.dart.
/// Other targets should use angular.dart instead.
/// @nodoc

export 'src/core/change_detection/pipe_transform.dart';
export 'src/core/di.dart';
export 'src/core/metadata.dart' show Component, Directive, Input, Output;
// TODO: move pipes into separate library target.
export 'src/core/metadata.dart' show Pipe;
export 'src/core/zone/ng_zone.dart' show NgZone, NgZoneError;
