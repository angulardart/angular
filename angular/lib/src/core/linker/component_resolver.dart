import 'package:meta/meta.dart';
import 'package:angular/src/reflector.dart' as reflector;
import 'package:angular/src/utilities.dart';

import 'component_factory.dart' show ComponentFactory;

/// Transitional API: Returns a [ComponentFactory] for [typeOrFactory].
///
/// If [typeOrFactory] is already a [ComponentFactory] this does nothing.
///
/// This API is slated for removal once the transition to factories is done.
@experimental
ComponentFactory<Object> typeToFactory(Object typeOrFactory) =>
    typeOrFactory is ComponentFactory<Object>
        ? typeOrFactory
        : unsafeCast(reflector.getComponent(unsafeCast(typeOrFactory)));
