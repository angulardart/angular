import 'dart:math';

import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/platform/dom/util.dart" show camelCaseToDashCase;

import "browser_details.dart" show BrowserDetails;
import "css_animation_options.dart" show CssAnimationOptions;

class Animation {
  dynamic element;
  CssAnimationOptions data;
  BrowserDetails browserDetails;
  static RegExp _durationRegExp;

  /// functions to be called upon completion
  List<Function> callbacks = [];

  /// the duration (ms) of the animation (whether from CSS or manually set)
  num computedDuration;

  /// the animation delay (ms) (whether from CSS or manually set)
  num computedDelay;

  /// timestamp of when the animation started */
  num startTime;

  /// functions for removing event listeners */
  List<Function> eventClearFunctions = [];

  /// flag used to track whether or not the animation has finished */
  bool completed = false;
  String _stringPrefix = "";

  /// total amount of time that the animation should take including delay///
  num get totalTime {
    var delay = computedDelay ?? 0;
    var duration = computedDuration ?? 0;
    return delay + duration;
  }

  /// Stores the start time and starts the animation
  Animation(this.element, this.data, this.browserDetails) {
    startTime = new DateTime.now().millisecondsSinceEpoch;
    _stringPrefix = DOM.getAnimationPrefix();
    setup();
    wait((timestamp) => start());
  }

  wait(Function callback) {
    // Firefox requires 2 frames for some reason
    browserDetails.raf(callback, 2);
  }

  ///  Sets up the initial styles before the animation is started
  void setup() {
    if (data.fromStyles != null) applyStyles(data.fromStyles);
    if (data.duration != null)
      applyStyles({"transitionDuration": data.duration.toString() + "ms"});
    if (data.delay != null)
      applyStyles({"transitionDelay": data.delay.toString() + "ms"});
  }

  /// After the initial setup has occurred, this method adds the animation styles
  void start() {
    addClasses(data.classesToAdd);
    addClasses(data.animationClasses);
    removeClasses(data.classesToRemove);
    if (data.toStyles != null) applyStyles(data.toStyles);
    var computedStyles = DOM.getComputedStyle(element);
    computedDelay = max(
        parseDurationString(computedStyles
            .getPropertyValue(_stringPrefix + "transition-delay")),
        parseDurationString(this
            .element
            .style
            .getPropertyValue(_stringPrefix + "transition-delay")));
    computedDuration = max(
        parseDurationString(computedStyles
            .getPropertyValue(_stringPrefix + "transition-duration")),
        parseDurationString(this
            .element
            .style
            .getPropertyValue(_stringPrefix + "transition-duration")));
    addEvents();
  }

  /// Applies the provided styles to the element
  void applyStyles(Map<String, dynamic> styles) {
    styles.forEach((String key, value) {
      var dashCaseKey = camelCaseToDashCase(key);
      if (DOM.getStyle(element, dashCaseKey) != null) {
        DOM.setStyle(element, dashCaseKey, value.toString());
      } else {
        DOM.setStyle(element, _stringPrefix + dashCaseKey, value.toString());
      }
    });
  }

  /// Adds the provided classes to the element
  void addClasses(List<String> classes) =>
      classes.forEach((String _class) => DOM.addClass(element, _class));

  /// Removes the provided classes from the element
  void removeClasses(List<String> classes) =>
      classes.forEach((String _class) => DOM.removeClass(element, _class));

  /// Adds events to track when animations have finished
  void addEvents() {
    if (totalTime > 0) {
      eventClearFunctions.add(DOM.onAndCancel(element, DOM.getTransitionEnd(),
          (dynamic event) => handleAnimationEvent(event)));
    } else {
      handleAnimationCompleted();
    }
  }

  void handleAnimationEvent(dynamic event) {
    var elapsedTime = (event.elapsedTime * 1000).round();
    if (!browserDetails.elapsedTimeIncludesDelay) elapsedTime += computedDelay;
    event.stopPropagation();
    if (elapsedTime >= totalTime) handleAnimationCompleted();
  }

  /// Runs all animation callbacks and removes temporary classes
  void handleAnimationCompleted() {
    removeClasses(data.animationClasses);
    callbacks.forEach((callback) => callback());
    callbacks = [];
    eventClearFunctions.forEach((fn) => fn());
    eventClearFunctions = [];
    completed = true;
  }

  /// Adds animation callbacks to be called upon completion
  Animation onComplete(Function callback) {
    if (completed) {
      callback();
    } else {
      callbacks.add(callback);
    }
    return this;
  }

  /// Converts the duration string to the number of milliseconds
  num parseDurationString(String duration) {
    var maxValue = 0;
    // duration must have at least 2 characters to be valid. (number + type)
    if (duration == null || duration.length < 2) {
      return maxValue;
    } else if (duration.substring(duration.length - 2) == "ms") {
      var value = int.parse(stripLetters(duration));
      if (value > maxValue) maxValue = value;
    } else if (duration.substring(duration.length - 1) == "s") {
      var ms = double.parse(stripLetters(duration)) * 1000;
      var value = ms.floor();
      if (value > maxValue) maxValue = value;
    }
    return maxValue;
  }

  /// Strips the letters from the duration string
  String stripLetters(String str) {
    _durationRegExp ??= new RegExp('[^0-9]+\$', caseSensitive: false);
    return str.replaceAll(_durationRegExp, '');
  }
}
