import 'dart:async';
import 'dart:html';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';
import 'package:angular/src/core/change_detection/constants.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/core/linker/style_encapsulation.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/runtime/dom_helpers.dart';

import 'render_view.dart';
import 'view.dart';

/// The base type of a view that implements a component's template.
///
/// For every component (a class annotated with `@Component()`), the compiler
/// will generate exactly one component view that extends this class. This view
/// is used to create and change detect the component, wherever it's used
/// declaratively in another component's template.
///
/// In addition to those of [RenderView], this view's responsibilities include:
///
///   * Initializing the component's [rootElement] based on its selector.
///
///   * Initializing the component's [componentStyles].
///
/// The type parameter [T] is the type of the component whose template this view
/// implements. Note that it's the responsibility of the [parentView] to
/// instantiate the component instance and provide it to this view via [create]
/// or [createAndProject]. This is necessary to implement certain hierarchical
/// dependency injection semantics.
abstract class ComponentView<T> extends RenderView {
  ComponentView(View parentView, int parentIndex, int changeDetectionMode)
      : _data =
            _ComponentViewData(parentView, parentIndex, changeDetectionMode);

  @override
  T ctx;

  @override
  ComponentStyles componentStyles;

  /// The root element of this component, created from its selector.
  HtmlElement rootElement;

  final _ComponentViewData _data;

  @override
  List<Object> get projectedNodes => _data.projectedNodes;

  @override
  View get parentView => _data.parentView;

  @override
  int get parentIndex => _data.parentIndex;

  /// Returns whether this component view uses default change detection.
  ///
  /// This is only exposed for `debugUsesDefaultChangeDetection` and should not
  /// be referenced by any other means.
  @experimental
  bool get usesDefaultChangeDetection =>
      _data.changeDetectionMode == ChangeDetectionStrategy.CheckAlways;

  // Initialization ------------------------------------------------------------

  // TODO(b/129005490): remove as this is always overridden by derived view.
  @override
  void build() {}

  /// Specialized [createAndProject] when there's no projected content.
  ///
  /// This exists purely as a code size optimization.
  @dart2js.noInline
  void create(T component) {
    createAndProject(component, const []);
  }

  /// Creates this view for [component] with [projectedNodes].
  ///
  /// The [projectedNodes] are any content placed between the opening and
  /// closing tags of [component].
  void createAndProject(T component, List<Object> projectedNodes) {
    ctx = component;
    _data.projectedNodes = projectedNodes;
    build();
  }

  /// Called by [build] once all subscriptions are created.
  @dart2js.noInline
  void initSubscriptions(List<StreamSubscription<void>> subscriptions) {
    _data.subscriptions = subscriptions;
  }

  /// Initializes styling to enable css shim for host element.
  ///
  /// The return value serves as a more efficient way of referencing
  /// [rootElement] within a component view's [build] implementation. It
  /// requires less code to assign the return value of a function that's going
  /// to be called anyways, than to generate an extra statement to load a field.
  @dart2js.noInline
  HtmlElement initViewRoot() {
    final hostElement = rootElement;
    final styles = componentStyles;
    if (styles.usesStyleEncapsulation) {
      updateClassBinding(hostElement, styles.hostPrefix, true);
    }
    return hostElement;
  }

  // Destruction ---------------------------------------------------------------

  @override
  void destroyInternalState() {
    if (!_data.destroyed) {
      _data.destroy();
      destroyInternal();
    }
  }

  // Change detection ----------------------------------------------------------

  @override
  bool get firstCheck =>
      _data.changeDetectorState == ChangeDetectorState.NeverChecked;

  @override
  void detectChanges() {
    if (_data.shouldSkipChangeDetection) {
      if (_data.changeDetectionMode == ChangeDetectionStrategy.Checked) {
        detectChangesInCheckAlwaysViews();
      }
      return;
    }

    // Sanity check in dev-mode that a destroyed view is not checked again.
    if (isDevMode && _data.destroyed) {
      throw StateError('detectChanges');
    }

    if (ChangeDetectionHost.checkForCrashes) {
      // Run change detection in "slow-mode" to catch thrown exceptions.
      detectCrash();
    } else {
      // Normally run change detection.
      detectChangesInternal();
    }

    // If we are a 'CheckOnce' component, we are done being checked.
    if (_data.changeDetectionMode == ChangeDetectionStrategy.CheckOnce) {
      _data.changeDetectionMode = ChangeDetectionStrategy.Checked;
    }

    // Set the state to already checked at least once.
    _data.changeDetectorState = ChangeDetectorState.CheckedBefore;
  }

  /// Generated code that is called by hosts.
  /// This is needed since deferred components don't allow call sites
  /// to use the explicit AppView type but require base class.
  void detectHostChanges(bool firstCheck) {}

  @override
  void disableChangeDetection() {
    _data.changeDetectorState = ChangeDetectorState.Errored;
  }

  /// Marks this view to be checked during change detection.
  ///
  /// Unlike [markForCheck], this does not mark this view's ancestry for change
  /// detection. This is also invoked *during* change detection as a means of
  /// invalidating this view when any of its [component]'s inputs change. This
  /// serves to propagate input changes down the component tree during a single
  /// change detection pass.
  void markAsCheckOnce() {
    _data.changeDetectionMode = ChangeDetectionStrategy.CheckOnce;
  }

  @override
  void markForCheck() {
    final changeDetectionMode = _data.changeDetectionMode;
    if (changeDetectionMode == ChangeDetectionStrategy.Detached) return;
    if (changeDetectionMode == ChangeDetectionStrategy.Checked) {
      markAsCheckOnce();
    }
    parentView.markForCheck();
  }

  @override
  void detach() {
    _data.changeDetectionMode = ChangeDetectionStrategy.Detached;
  }

  @override
  void reattach() {
    _data.changeDetectionMode = ChangeDetectionStrategy.CheckAlways;
    markForCheck();
  }

  // Styling -------------------------------------------------------------------

  @dart2js.noInline
  @override
  void updateChildClass(HtmlElement element, String newClass) {
    if (element == rootElement) {
      final styles = componentStyles;
      final shim = styles.usesStyleEncapsulation;
      element.className = shim ? '$newClass ${styles.hostPrefix}' : newClass;
      final parent = parentView;
      if (parent is RenderView) {
        parent.addShimC(element);
      }
    } else {
      super.updateChildClass(element, newClass);
    }
  }

  @dart2js.noInline
  @override
  void updateChildClassNonHtml(Element element, String newClass) {
    if (element == rootElement) {
      final styles = componentStyles;
      final shim = styles.usesStyleEncapsulation;
      updateAttribute(
          element, 'class', shim ? '$newClass ${styles.hostPrefix}' : newClass);
      final parent = parentView;
      if (parent is RenderView) {
        parent.addShimE(element);
      }
    } else {
      super.updateChildClassNonHtml(element, newClass);
    }
  }
}

/// Data for [ComponentView] bundled together as an optimization.
@sealed
class _ComponentViewData implements RenderViewData {
  @dart2js.noInline
  factory _ComponentViewData(
    View parentView,
    int parentIndex,
    int changeDetectionMode,
  ) {
    return _ComponentViewData._(parentView, parentIndex, changeDetectionMode);
  }

  _ComponentViewData._(
    this.parentView,
    this.parentIndex,
    this._changeDetectionMode,
  );

  @override
  final View parentView;

  @override
  final int parentIndex;

  @override
  List<Object> projectedNodes;

  @override
  List<StreamSubscription<void>> subscriptions;

  @override
  int get changeDetectionMode => _changeDetectionMode;
  int _changeDetectionMode;
  set changeDetectionMode(int mode) {
    if (_changeDetectionMode != mode) {
      _changeDetectionMode = mode;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  int get changeDetectorState => _changeDetectorState;
  int _changeDetectorState = ChangeDetectorState.NeverChecked;
  set changeDetectorState(int state) {
    if (_changeDetectorState != state) {
      _changeDetectorState = state;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  bool get destroyed => _destroyed;
  bool _destroyed = false;

  @override
  bool get shouldSkipChangeDetection => _shouldSkipChangeDetection;
  bool _shouldSkipChangeDetection = false;

  @override
  void destroy() {
    _destroyed = true;
    if (subscriptions != null) {
      for (var i = 0, length = subscriptions.length; i < length; ++i) {
        subscriptions[i].cancel();
      }
    }
  }

  void _updateShouldSkipChangeDetection() {
    _shouldSkipChangeDetection =
        _changeDetectionMode == ChangeDetectionStrategy.Checked ||
            _changeDetectionMode == ChangeDetectionStrategy.Detached ||
            _changeDetectorState == ChangeDetectorState.Errored;
  }
}
