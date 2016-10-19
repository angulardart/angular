import "package:angular2/src/core/di.dart" show Provider, SkipSelf, Optional;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "../change_detector_ref.dart" show ChangeDetectorRef;

/// A differ that tracks changes made to an object over time.
abstract class KeyValueDiffer<T> {
  diff(T object);
  void onDestroy();
}

/// Provides a factory for [KeyValueDiffer].
abstract class KeyValueDifferFactory {
  bool supports(dynamic objects);
  KeyValueDiffer create(ChangeDetectorRef cdRef);
}

/// A repository of different Map diffing strategies used by NgClass, NgStyle,
/// and others.
class KeyValueDiffers {
  final List<KeyValueDifferFactory> factories;
  const KeyValueDiffers(this.factories);
  static KeyValueDiffers create(List<KeyValueDifferFactory> factories,
      [KeyValueDiffers parent]) {
    if (parent != null) {
      var copied = new List<KeyValueDifferFactory>.from(parent.factories);
      factories =
          (new List<KeyValueDifferFactory>.from(factories)..addAll(copied));
      return new KeyValueDiffers(factories);
    } else {
      return new KeyValueDiffers(factories);
    }
  }

  /// Takes an array of [KeyValueDifferFactory] and returns a provider used to
  /// extend the inherited [KeyValueDiffers] instance with the provided
  /// factories and return a new [KeyValueDiffers] instance.
  ///
  /// The following example shows how to extend an existing list of factories,
  /// which will only be applied to the injector for this component and its
  /// children.  This step is all that's required to make a new [KeyValueDiffer]
  /// available.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @Component(
  ///   viewProviders: const [
  ///     const KeyValueDiffers([new ImmutableMapDiffer()])
  ///   ]
  /// )
  /// ```
  static Provider extend(List<KeyValueDifferFactory> factories) {
    return new Provider(KeyValueDiffers, useFactory: (KeyValueDiffers parent) {
      if (parent == null) {
        // Typically would occur when calling KeyValueDiffers.extend inside of
        // dependencies passed to bootstrap(), which would override default
        // pipes instead of extending them.
        throw new BaseException(
            'Cannot extend KeyValueDiffers without a parent injector');
      }
      return KeyValueDiffers.create(factories, parent);
    }, deps: [
      [KeyValueDiffers, new SkipSelf(), new Optional()]
    ]);
  }

  KeyValueDifferFactory find(Object kv) {
    var factory;
    var factoryCount = factories.length;
    for (var i = 0; i < factoryCount; i++) {
      var f = factories[i];
      if (f.supports(kv)) {
        factory = f;
        break;
      }
    }
    if (factory != null) {
      return factory;
    } else {
      throw new BaseException(
          'Cannot find a differ supporting object \'${ kv}\'');
    }
  }
}
