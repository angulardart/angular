import "package:angular2/core.dart"
    show
        Directive,
        ViewContainerRef,
        TemplateRef,
        ContentChildren,
        QueryList,
        Attribute,
        AfterContentInit,
        Input;

import "ng_switch.dart" show SwitchView;

const _CATEGORY_DEFAULT = "other";

@Deprecated('Copy into your own project if needed, no longer supported')
abstract class NgLocalization {
  String getPluralCategory(dynamic value);
}

/// `ngPlural` is an i18n directive that displays DOM sub-trees that match the
/// switch expression value, or failing that, DOM sub-trees that match the
/// switch expression's pluralization category.
///
/// To use this directive, you must provide an extension of `NgLocalization`
/// that maps values to category names. You then define a container element that
/// sets the `[ngPlural]` attribute to a switch expression.
///    - Inner elements defined with an `[ngPluralCase]` attribute will display
///    based on their expression.
///    - If `[ngPluralCase]` is set to a value starting with `=`, it will only
///    display if the value matches the switch expression exactly.
///    - Otherwise, the view will be treated as a "category match", and will
///    only display if exact value matches aren't found and the value maps to
///    its category using the `getPluralCategory` function provided.
///
/// If no matching views are found for a switch expression, inner elements
/// marked `[ngPluralCase]="other"` will be displayed.
///
/// ```dart
/// class MyLocalization extends NgLocalization {
///    getPluralCategory(value: any) {
///       if(value < 5) {
///          return 'few';
///       }
///    }
/// }
///
/// @Component(
///    selector: 'app',
///    providers: const [provide(NgLocalization, {useClass: MyLocalization})]
/// )
/// @View(
///   template: '''
///     <p>Value = {{value}}</p>
///     <button (click)="inc()">Increment</button>
///
///     <div [ngPlural]="value">
///       <template ngPluralCase="=0">there is nothing</template>
///       <template ngPluralCase="=1">there is one</template>
///       <template ngPluralCase="few">there are a few</template>
///       <template ngPluralCase="other">there is some number</template>
///     </div>
///   ''',
///   directives: const [NgPlural, NgPluralCase]
/// )
/// class App {
///   dynamic value = 'init';
///
///   void inc() {
///     value = value === 'init' ? 0 : value + 1;
///   }
/// }
/// ```
@Deprecated('Copy into your own project if needed, no longer supported')
@Directive(selector: "[ngPluralCase]")
class NgPluralCase {
  String value;
  SwitchView _view;
  NgPluralCase(@Attribute("ngPluralCase") this.value, TemplateRef template,
      ViewContainerRef viewContainer) {
    this._view = new SwitchView(viewContainer, template);
  }
}

@Deprecated('Copy into your own project if needed, no longer supported')
@Directive(selector: "[ngPlural]")
class NgPlural implements AfterContentInit {
  NgLocalization _localization;
  num _switchValue;
  SwitchView _activeView;
  var _caseViews = new Map<dynamic, SwitchView>();
  @ContentChildren(NgPluralCase)
  QueryList<NgPluralCase> cases;
  NgPlural(this._localization);
  @Input()
  set ngPlural(num value) {
    this._switchValue = value;
    this._updateView();
  }

  @override
  void ngAfterContentInit() {
    this.cases.forEach(/* void */ (NgPluralCase pluralCase) {
      this._caseViews[this._formatValue(pluralCase)] = pluralCase._view;
    });
    this._updateView();
  }

  void _updateView() {
    _clearViews();
    SwitchView view =
        _caseViews[_switchValue] ?? _getCategoryView(_switchValue);
    _activateView(view);
  }

  void _clearViews() {
    _activeView?.destroy();
  }

  void _activateView(SwitchView view) {
    if (view == null) return;
    this._activeView = view;
    this._activeView.create();
  }

  SwitchView _getCategoryView(num value) {
    String category = this._localization.getPluralCategory(value);
    SwitchView categoryView = this._caseViews[category];
    return categoryView ?? _caseViews[_CATEGORY_DEFAULT];
  }

  bool _isValueView(NgPluralCase pluralCase) {
    return identical(pluralCase.value[0], "=");
  }

  dynamic _formatValue(NgPluralCase pluralCase) {
    return this._isValueView(pluralCase)
        ? this._stripValue(pluralCase.value)
        : pluralCase.value;
  }

  num _stripValue(String value) {
    return int.parse(value.substring(1), radix: 10);
  }
}
