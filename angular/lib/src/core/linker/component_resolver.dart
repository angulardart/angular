import 'package:angular/src/runtime.dart';
import 'package:angular/src/di/reflector.dart' as reflector;
import 'package:meta/meta.dart';

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
        : unsafeCast<ComponentFactory<Object>>(
            reflector.getComponent(unsafeCast<Type>(typeOrFactory)));
