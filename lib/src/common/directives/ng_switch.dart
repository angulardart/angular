import "package:angular2/core.dart"
    show Directive, Host, ViewContainerRef, TemplateRef;

const _WHEN_DEFAULT = const Object();

class SwitchView {
  ViewContainerRef _viewContainerRef;
  TemplateRef _templateRef;

  SwitchView(this._viewContainerRef, this._templateRef);

  void create() {
    this._viewContainerRef.createEmbeddedView(this._templateRef);
  }

  void destroy() {
    this._viewContainerRef.clear();
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
/// {@example docs/template-syntax/lib/app_component.html region=NgSwitch-expanded}
///
/// Try the [live example][ex].
/// See the [Template Syntax section on `ngSwitch`][guide] for more details.
///
/// [ex]: examples/template-syntax/#ngSwitch
/// [guide]: docs/guide/template-syntax.html#ngSwitch
@Directive(selector: "[ngSwitch]", inputs: const ["ngSwitch"])
class NgSwitch {
  dynamic _switchValue;
  bool _useDefault = false;
  var _valueViews = new Map<dynamic, List<SwitchView>>();
  List<SwitchView> _activeViews = [];
  set ngSwitch(dynamic value) {
    // Empty the currently active ViewContainers
    this._emptyAllActiveViews();
    // Add the ViewContainers matching the value (with a fallback to default)
    this._useDefault = false;
    var views = this._valueViews[value];
    if (views == null) {
      this._useDefault = true;
      views = this._valueViews[_WHEN_DEFAULT];
    }
    this._activateViews(views);
    this._switchValue = value;
  }

  void _onWhenValueChanged(dynamic oldWhen, dynamic newWhen, SwitchView view) {
    this._deregisterView(oldWhen, view);
    this._registerView(newWhen, view);
    if (identical(oldWhen, this._switchValue)) {
      view.destroy();
      _activeViews.remove(view);
    } else if (identical(newWhen, this._switchValue)) {
      if (this._useDefault) {
        this._useDefault = false;
        this._emptyAllActiveViews();
      }
      view.create();
      this._activeViews.add(view);
    }
    // Switch to default when there is no more active ViewContainers
    if (identical(this._activeViews.length, 0) && !this._useDefault) {
      this._useDefault = true;
      this._activateViews(this._valueViews[_WHEN_DEFAULT]);
    }
  }

  void _emptyAllActiveViews() {
    var activeContainers = this._activeViews;
    for (var i = 0; i < activeContainers.length; i++) {
      activeContainers[i].destroy();
    }
    this._activeViews = [];
  }

  void _activateViews(List<SwitchView> views) {
    // TODO(vicb): assert(this._activeViews.length === 0);
    if (views != null) {
      for (var i = 0; i < views.length; i++) {
        views[i].create();
      }
      this._activeViews = views;
    }
  }

  void _registerView(dynamic value, SwitchView view) {
    var views = this._valueViews[value];
    if (views == null) {
      views = [];
      this._valueViews[value] = views;
    }
    views.add(view);
  }

  void _deregisterView(dynamic value, SwitchView view) {
    // `_WHEN_DEFAULT` is used a marker for non-registered whens
    if (identical(value, _WHEN_DEFAULT)) return;
    var views = this._valueViews[value];
    if (views.length == 1) {
      (this._valueViews.containsKey(value) &&
          (this._valueViews.remove(value) != null || true));
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
@Directive(selector: "[ngSwitchWhen]", inputs: const ["ngSwitchWhen"])
class NgSwitchWhen {
  // `_WHEN_DEFAULT` is used as a marker for a not yet initialized value

  dynamic _value = _WHEN_DEFAULT;
  SwitchView _view;
  NgSwitch _switch;
  NgSwitchWhen(ViewContainerRef viewContainer, TemplateRef templateRef,
      @Host() NgSwitch ngSwitch) {
    this._switch = ngSwitch;
    this._view = new SwitchView(viewContainer, templateRef);
  }
  set ngSwitchWhen(dynamic value) {
    this._switch._onWhenValueChanged(this._value, value, this._view);
    this._value = value;
  }
}

/// Default case statements are displayed when no match expression matches the
/// switch expression value.
///
/// See [NgSwitch] for more details and example.
@Directive(selector: "[ngSwitchDefault]")
class NgSwitchDefault {
  NgSwitchDefault(ViewContainerRef viewContainer, TemplateRef templateRef,
      @Host() NgSwitch sswitch) {
    sswitch._registerView(
        _WHEN_DEFAULT, new SwitchView(viewContainer, templateRef));
  }
}
