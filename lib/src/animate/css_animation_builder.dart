import "animation.dart" show Animation;
import "browser_details.dart" show BrowserDetails;
import "css_animation_options.dart" show CssAnimationOptions;

class CssAnimationBuilder {
  BrowserDetails browserDetails;

  /// @type {CssAnimationOptions}
  CssAnimationOptions data = new CssAnimationOptions();

  /// Accepts public properties for CssAnimationBuilder
  CssAnimationBuilder(this.browserDetails);

  /// Adds a temporary class that will be removed at the end of the animation
  CssAnimationBuilder addAnimationClass(String className) {
    data.animationClasses.add(className);
    return this;
  }

  /// Adds a class that will remain on the element after the animation has finished
  CssAnimationBuilder addClass(String className) {
    data.classesToAdd.add(className);
    return this;
  }

  /// Removes a class from the element
  CssAnimationBuilder removeClass(String className) {
    data.classesToRemove.add(className);
    return this;
  }

  /// Sets the animation duration (and overrides any defined through CSS)
  CssAnimationBuilder setDuration(num duration) {
    data.duration = duration;
    return this;
  }

  /// Sets the animation delay (and overrides any defined through CSS)
  CssAnimationBuilder setDelay(num delay) {
    data.delay = delay;
    return this;
  }

  /// Sets styles for both the initial state and the destination state
  CssAnimationBuilder setStyles(
          Map<String, dynamic> from, Map<String, dynamic> to) =>
      setFromStyles(from).setToStyles(to);

  /// Sets the initial styles for the animation
  CssAnimationBuilder setFromStyles(Map<String, dynamic> from) {
    data.fromStyles = from;
    return this;
  }

  /// Sets the destination styles for the animation
  CssAnimationBuilder setToStyles(Map<String, dynamic> to) {
    data.toStyles = to;
    return this;
  }

  /// Starts the animation and returns a promise
  Animation start(dynamic element) =>
      new Animation(element, data, browserDetails);
}
