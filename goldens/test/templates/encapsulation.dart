@JS()
library golden;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import 'encapsulation.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    NoEncapsulation,
    EmulatedEncapsulation,
  ],
  template: '''
    <no-encapsulation
      [floatingLabel]="floatingLabel"
      [trailingGlyphAriaLabel]="trailingLabel"
      [disabled]="disabled"
    >
      <div trailing>
        Hello <span class="highlight {{addClass}}">World!</span>
      </div>
    </no-encapsulation>
    <emulated-encapsulation
      [floatingLabel]="floatingLabel"
      [trailingGlyphAriaLabel]="trailingLabel"
      [disabled]="disabled"
    >
      <div trailing>
        Hello <span class="highlight {{addClass}}">World!</span>
      </div>
    </emulated-encapsulation>
  ''',
)
class GoldenComponent {
  bool floatingLabel = deopt();
  String trailingLabel = deopt();
  bool disabled = deopt();
  String addClass = deopt();
}

@Component(
  selector: 'no-encapsulation',
  template: '''
    <span class="trailing-text"
          [class.floated-label]="floatingLabel">
      <div class="glyph trailing"
            [attr.aria-label]="trailingGlyphAriaLabel"
            [attr.disabled.if]="disabled">
      </div>
    </span>
    <ng-content select="[trailing]">
    </ng-content>
  ''',
  styles: [
    '''
    :host {
      display: inline-flex;
    }
    :host(.ltr) .top-section {
      /*! @noflip */
      direction: ltr;
    }
    [trailing] {
      font-weight: bold;
    }
    ::ng-deep .link {
      text-decoration: none;
    }
    .has-links ::ng-deep .link {
      text-decoration: none;
    }
    '''
  ],
  encapsulation: ViewEncapsulation.None,
)
class NoEncapsulation {
  @Input()
  var floatingLabel = false;

  @Input()
  String? trailingGlyphAriaLabel;

  @Input()
  var disabled = false;
}

@Component(
  selector: 'emulated-encapsulation',
  template: '''
    <span class="trailing-text"
          [class.floated-label]="floatingLabel">
      <div class="glyph trailing"
           [attr.aria-label]="trailingGlyphAriaLabel"
           [attr.disabled.if]="disabled">
      </div>
    </span>
    <ng-content select="[trailing]">
    </ng-content>
  ''',
  styles: [
    '''
    :host {
      display: inline-flex;
    }
    :host(.ltr) .top-section {
      /*! @noflip */
      direction: ltr;
    }
    [trailing] {
      font-weight: bold;
    }
    ::ng-deep .link {
      text-decoration: none;
    }
    .has-links ::ng-deep .link {
      text-decoration: none;
    }
    '''
  ],
)
class EmulatedEncapsulation {
  @Input()
  var floatingLabel = false;

  @Input()
  String? trailingGlyphAriaLabel;

  @Input()
  var disabled = false;
}
