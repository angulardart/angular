import "package:angular2/src/core/di.dart" show Injectable;

import "browser_details.dart" show BrowserDetails;
import "css_animation_builder.dart" show CssAnimationBuilder;

@Injectable()
class AnimationBuilder {
  BrowserDetails browserDetails;

  /// Used for DI
  AnimationBuilder(this.browserDetails);

  /// Creates a new CSS Animation
  CssAnimationBuilder css() => new CssAnimationBuilder(browserDetails);
}
