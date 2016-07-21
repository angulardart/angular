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
import "package:angular2/src/facade/collection.dart" show Map;
import "package:angular2/src/facade/lang.dart" show isPresent, NumberWrapper;

import "ng_switch.dart" show SwitchView;

const _CATEGORY_DEFAULT = "other";

abstract class NgLocalization {
  String getPluralCategory(dynamic value);
}

/**
 * `ngPlural` is an i18n directive that displays DOM sub-trees that match the switch expression
 * value, or failing that, DOM sub-trees that match the switch expression's pluralization category.
 *
 * To use this directive, you must provide an extension of `NgLocalization` that maps values to
 * category names. You then define a container element that sets the `[ngPlural]` attribute to a
 * switch expression.
 *    - Inner elements defined with an `[ngPluralCase]` attribute will display based on their
 * expression.
 *    - If `[ngPluralCase]` is set to a value starting with `=`, it will only display if the value
 * matches the switch expression exactly.
 *    - Otherwise, the view will be treated as a "category match", and will only display if exact
 * value matches aren't found and the value maps to its category using the `getPluralCategory`
 * function provided.
 *
 * If no matching views are found for a switch expression, inner elements marked
 * `[ngPluralCase]="other"` will be displayed.
 *
 * ```typescript
 * class MyLocalization extends NgLocalization {
 *    getPluralCategory(value: any) {
 *       if(value < 5) {
 *          return 'few';
 *       }
 *    }
 * }
 *
 * @Component({
 *    selector: 'app',
 *    providers: [provide(NgLocalization, {useClass: MyLocalization})]
 * })
 * @View({
 *   template: `
 *     <p>Value = {{value}}</p>
 *     <button (click)="inc()">Increment</button>
 *
 *     <div [ngPlural]="value">
 *       <template ngPluralCase="=0">there is nothing</template>
 *       <template ngPluralCase="=1">there is one</template>
 *       <template ngPluralCase="few">there are a few</template>
 *       <template ngPluralCase="other">there is some number</template>
 *     </div>
 *   `,
 *   directives: [NgPlural, NgPluralCase]
 * })
 * export class App {
 *   value = 'init';
 *
 *   inc() {
 *     this.value = this.value === 'init' ? 0 : this.value + 1;
 *   }
 * }
 *
 * ```
 */
@Directive(selector: "[ngPluralCase]")
class NgPluralCase {
  String value;
  /** @internal */
  SwitchView _view;
  NgPluralCase(@Attribute("ngPluralCase") this.value, TemplateRef template,
      ViewContainerRef viewContainer) {
    this._view = new SwitchView(viewContainer, template);
  }
}

@Directive(selector: "[ngPlural]")
class NgPlural implements AfterContentInit {
  NgLocalization _localization;
  num _switchValue;
  SwitchView _activeView;
  var _caseViews = new Map<dynamic, SwitchView>();
  @ContentChildren(NgPluralCase)
  QueryList<NgPluralCase> cases = null;
  NgPlural(this._localization) {}
  @Input()
  set ngPlural(num value) {
    this._switchValue = value;
    this._updateView();
  }

  ngAfterContentInit() {
    this.cases.forEach(/* void */ (NgPluralCase pluralCase) {
      this._caseViews[this._formatValue(pluralCase)] = pluralCase._view;
    });
    this._updateView();
  }

  /** @internal */
  void _updateView() {
    this._clearViews();
    SwitchView view = this._caseViews[this._switchValue];
    if (!isPresent(view)) view = this._getCategoryView(this._switchValue);
    this._activateView(view);
  }

  /** @internal */
  _clearViews() {
    if (isPresent(this._activeView)) this._activeView.destroy();
  }

  /** @internal */
  _activateView(SwitchView view) {
    if (!isPresent(view)) return;
    this._activeView = view;
    this._activeView.create();
  }

  /** @internal */
  SwitchView _getCategoryView(num value) {
    String category = this._localization.getPluralCategory(value);
    SwitchView categoryView = this._caseViews[category];
    return isPresent(categoryView)
        ? categoryView
        : this._caseViews[_CATEGORY_DEFAULT];
  }

  /** @internal */
  bool _isValueView(NgPluralCase pluralCase) {
    return identical(pluralCase.value[0], "=");
  }

  /** @internal */
  dynamic _formatValue(NgPluralCase pluralCase) {
    return this._isValueView(pluralCase)
        ? this._stripValue(pluralCase.value)
        : pluralCase.value;
  }

  /** @internal */
  num _stripValue(String value) {
    return NumberWrapper.parseInt(value.substring(1), 10);
  }
}
