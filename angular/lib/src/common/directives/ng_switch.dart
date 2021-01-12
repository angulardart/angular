import 'package:angular/src/core/linker.dart';
import 'package:angular/src/meta.dart';

const _WHEN_DEFAULT = Object();

class SwitchView {
  final ViewContainerRef _viewContainerRef;
  final TemplateRef _templateRef;

  SwitchView(this._viewContainerRef, this._templateRef);

  void create() {
    _viewContainerRef.createEmbeddedView(_templateRef);
  }

  void destroy() {
    _viewContainerRef.clear();
  }
}

/// Adds or removes DOM sub-trees when their match expressions match the switch
/// expression.
///
/// Elements within [NgSwitch] but without [NgSwitchWhen] or [NgSwitchDefault]
/// directives will be preserved at the location as specified in the template.
///
/// [NgSwitch] simply inserts nested elements based on which match expression
/// matches the value obtained from the evaluated switch expression. In other
/// words, you define a container element (where you place the directive with a
/// switch expression on the `[ngSwitch]="..."` property), define any inner
/// elements inside of the directive and place a `[ngSwitchWhen]` property per
/// element.
///
/// [NgSwitchWhen] is used to inform `NgSwitch` which element to
/// display when the expression is evaluated. If a matching expression is not
/// found via `ngSwitchWhen` then an element with an
/// [NgSwitchDefault] is displayed.
///
/// ### Examples
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (ngswitch)"?>
/// ```html
/// <div [ngSwitch]="hero?.emotion">
///   <happy-hero    *ngSwitchCase="'happy'"    [hero]="hero"></happy-hero>
///   <sad-hero      *ngSwitchCase="'sad'"      [hero]="hero"></sad-hero>
///   <confused-hero *ngSwitchCase="'confused'" [hero]="hero"></confused-hero>
///   <unknown-hero  *ngSwitchDefault           [hero]="hero"></unknown-hero>
/// </div>
/// ```
///
/// <?code-excerpt "docs/structural-directives/lib/app_component.html (ngswitch-template)"?>
/// ```html
/// <div [ngSwitch]="hero?.emotion">
///   <template [ngSwitchCase]="'happy'">
///     <happy-hero [hero]="hero"></happy-hero>
///   </template>
///   <template [ngSwitchCase]="'sad'">
///     <sad-hero [hero]="hero"></sad-hero>
///   </template>
///   <template [ngSwitchCase]="'confused'">
///     <confused-hero [hero]="hero"></confused-hero>
///   </template >
///   <template ngSwitchDefault>
///     <unknown-hero [hero]="hero"></unknown-hero>
///   </template>
/// </div>
/// ```
///
/// Try the [live example][ex].
/// For details, see the [Structural Directives section on `ngSwitch`][guide].
///
/// [ex]: https://angulardart.dev/examples/template-syntax#ngSwitch
/// [guide]: https://webdev.dartlang.org/angular/guide/structural-directives.html#ngSwitch
///
@Directive(
  selector: '[ngSwitch]',
  visibility: Visibility.all,
)
class NgSwitch {
  dynamic _switchValue;
  bool _useDefault = false;
  final _valueViews = <dynamic, List<SwitchView>>{};

  List<SwitchView> _activeViews = [];

  @Input()
  set ngSwitch(dynamic value) {
    // Calculate set of views to display for this value.
    var views = _valueViews[value];
    if (views != null) {
      _useDefault = false;
    } else {
      // Since there is no matching view for the value and there is no
      // default case, nothing to do just return.
      if (_useDefault) return;
      _useDefault = true;
      views = _valueViews[_WHEN_DEFAULT];
    }
    _emptyAllActiveViews();
    _activateViews(views);
    _switchValue = value;
  }

  void _onWhenValueChanged(dynamic oldWhen, dynamic newWhen, SwitchView view) {
    _deregisterView(oldWhen, view);
    _registerView(newWhen, view);
    if (identical(oldWhen, _switchValue)) {
      view.destroy();
      _activeViews.remove(view);
    } else if (identical(newWhen, _switchValue)) {
      if (_useDefault) {
        _useDefault = false;
        _emptyAllActiveViews();
      }
      view.create();
      _activeViews.add(view);
    }
    // Switch to default when there is no more active ViewContainers
    if (identical(_activeViews.length, 0) && !_useDefault) {
      _useDefault = true;
      _activateViews(_valueViews[_WHEN_DEFAULT]);
    }
  }

  void _emptyAllActiveViews() {
    var activeContainers = _activeViews;
    for (var i = 0, len = activeContainers.length; i < len; i++) {
      activeContainers[i].destroy();
    }
    _activeViews = [];
  }

  void _activateViews(List<SwitchView>? views) {
    if (views == null) return;
    for (var i = 0, len = views.length; i < len; i++) {
      views[i].create();
    }
    _activeViews = views;
  }

  void _registerView(dynamic value, SwitchView view) {
    var views = _valueViews[value];
    if (views == null) {
      views = <SwitchView>[];
      _valueViews[value] = views;
    }
    views.add(view);
  }

  void _deregisterView(dynamic value, SwitchView view) {
    // `_WHEN_DEFAULT` is used a marker for non-registered whens
    if (identical(value, _WHEN_DEFAULT)) return;
    var views = _valueViews[value];
    if (views!.length == 1) {
      _valueViews.remove(value);
    } else {
      views.remove(view);
    }
  }
}

/// Insert the sub-tree when the `ngSwitchWhen` expression evaluates to the same
/// value as the enclosing switch expression.
///
/// If multiple match expression match the switch expression value, all of them
/// are displayed.
///
/// See [NgSwitch] for more details and example.
///
@Directive(
  selector: '[ngSwitchWhen],[ngSwitchCase]',
)
class NgSwitchWhen {
  final NgSwitch _switch;
  final SwitchView _view;

  /// Used as a marker for an uninitialized value.
  dynamic _value = _WHEN_DEFAULT;

  NgSwitchWhen(
    ViewContainerRef viewContainer,
    TemplateRef templateRef,
    @Host() this._switch,
  ) : _view = SwitchView(viewContainer, templateRef);

  @Input()
  set ngSwitchCase(dynamic value) {
    ngSwitchWhen = value;
  }

  @Input()
  set ngSwitchWhen(dynamic value) {
    if (identical(value, _value)) return;
    _switch._onWhenValueChanged(_value, value, _view);
    _value = value;
  }
}

/// Default case statements are displayed when no match expression matches the
/// switch expression value.
///
/// See [NgSwitch] for more details and example.
///
@Directive(
  selector: '[ngSwitchDefault]',
)
class NgSwitchDefault {
  NgSwitchDefault(ViewContainerRef viewContainer, TemplateRef templateRef,
      @Host() NgSwitch switchDirective) {
    switchDirective._registerView(
        _WHEN_DEFAULT, SwitchView(viewContainer, templateRef));
  }
}
