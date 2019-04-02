import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';

/// An experimental change detection mixin/base class for specific use cases.
///
/// Instead of setting `changeDetection: ChangeDetectionStrategy.*`, you may
/// extend or mixin [ComponentState]. By doing so, the [setState] instance
/// method becomes the only mechanism in which the component will be checked
/// by change detection.
///
/// Unlike `ChangeDetectionStrategy.OnPush`:
/// * You may override `@Input`-annotated setters and call [setState].
/// * Some lifecycle events (such as `AfterChanges`, `OnChanges`) are rejected.
///
/// **WARNING**: It is currently undefined behavior to mix a component that is
/// using  [ComponentState] with children that use another change detection
/// type, and as such it is highly suggested to only use [ComponentState] on
/// components that represent a low-level repeated component, such as a cell in
/// a table, and in other cases to use `ChangeDetectionStrategy.OnPush`.
///
/// It is not valid to use `implements` with this class.
@experimental
abstract class ComponentState {
  void Function() _onStateChanged;

  /// Invokes the provided function and schedules change detection to occur.
  ///
  /// For implementing `@Input()`:
  /// ```
  ///   @Input()
  ///   set title(String newValue) {
  ///     setState(() {
  ///       titleToRender = newValue;
  ///     });
  ///   }
  /// ```
  ///
  /// For reacting to other events (such as RPCs):
  /// ```
  ///   void invokeRpc(RpcService rpcService) async {
  ///     final users = await rpcService.fetchUsers;
  ///     setState(() {
  ///       usersToRender = users;
  ///     });
  ///   }
  /// ```
  ///
  /// Only invoke this method within a class that implements [ComponentState].
  @protected
  void setState(void Function() scheduleChangeDetectionAfter) {
    scheduleChangeDetectionAfter();
    deliverStateChanges();
  }

  /// Semantically identical to calling `setState((){})`.
  ///
  /// **DEPRECATED**: Due to changes in the testing framework, it is no longer
  /// necessary to override or invoke this method at all in order to reflect
  /// changes to the DOM, and it will be removed at a future point in time.
  @Deprecated('Do not override this method. It will be removed')
  @protected
  void deliverStateChanges() {
    final onStateChanged = _onStateChanged;
    if (onStateChanged != null) {
      onStateChanged();
    }
  }
}

/// **INTERNAL ONLY**: Used to configure a [ComponentState] implementation.
@dart2js.tryInline
void internalSetStateChanged(
  ComponentState component,
  void Function() onStateChanged,
) {
  component._onStateChanged = onStateChanged;
}
