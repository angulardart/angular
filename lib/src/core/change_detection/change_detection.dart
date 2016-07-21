import "differs/default_iterable_differ.dart" show DefaultIterableDifferFactory;
import "differs/default_keyvalue_differ.dart" show DefaultKeyValueDifferFactory;
import "differs/iterable_differs.dart"
    show IterableDiffers, IterableDifferFactory;
import "differs/keyvalue_differs.dart"
    show KeyValueDiffers, KeyValueDifferFactory;

export "change_detection_util.dart"
    show
        WrappedValue,
        ValueUnwrapper,
        SimpleChange,
        devModeEqual,
        looseIdentical,
        uninitialized;
export "change_detector_ref.dart" show ChangeDetectorRef;
export "constants.dart"
    show
        ChangeDetectionStrategy,
        CHANGE_DETECTION_STRATEGY_VALUES,
        ChangeDetectorState,
        CHANGE_DETECTOR_STATE_VALUES,
        isDefaultChangeDetectionStrategy;
export "differs/default_iterable_differ.dart"
    show DefaultIterableDifferFactory, CollectionChangeRecord;
export "differs/default_keyvalue_differ.dart"
    show DefaultKeyValueDifferFactory, KeyValueChangeRecord;
export "differs/iterable_differs.dart"
    show IterableDiffers, IterableDiffer, IterableDifferFactory, TrackByFn;
export "differs/keyvalue_differs.dart"
    show KeyValueDiffers, KeyValueDiffer, KeyValueDifferFactory;
export "pipe_transform.dart" show PipeTransform;

/**
 * Structural diffing for `Object`s and `Map`s.
 */
const List<KeyValueDifferFactory> keyValDiff = const [
  const DefaultKeyValueDifferFactory()
];
/**
 * Structural diffing for `Iterable` types such as `Array`s.
 */
const List<IterableDifferFactory> iterableDiff = const [
  const DefaultIterableDifferFactory()
];
const defaultIterableDiffers = const IterableDiffers(iterableDiff);
const defaultKeyValueDiffers = const KeyValueDiffers(keyValDiff);
