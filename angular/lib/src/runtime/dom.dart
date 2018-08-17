/// Proposal for shared DOM functions across the codebase to reduce code size.
///
/// Not currently used in production.
library angular.src.runtime.view;

import 'dart:html' show Comment;

import 'package:meta/dart2js.dart' as dart2js;

@dart2js.tryInline
Comment comment() => new Comment();
