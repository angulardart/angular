@TestOn('browser')

import "package:angular2/src/animate/animation_builder.dart"
    show AnimationBuilder;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("AnimationBuilder", () {
    test("should have data object", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        expect(animateCss.data, isNotNull);
      });
    });
    test("should allow you to add classes", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        animateCss.addClass("some-class");
        expect(animateCss.data.classesToAdd, ['some-class']);
        animateCss.addClass("another-class");
        expect(animateCss.data.classesToAdd, ["some-class", "another-class"]);
      });
    });
    test("should allow you to add temporary classes", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        animateCss.addAnimationClass("some-class");
        expect(animateCss.data.animationClasses, ["some-class"]);
        animateCss.addAnimationClass("another-class");
        expect(
            animateCss.data.animationClasses, ["some-class", "another-class"]);
      });
    });
    test("should allow you to remove classes", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        animateCss.removeClass("some-class");
        expect(animateCss.data.classesToRemove, ["some-class"]);
        animateCss.removeClass("another-class");
        expect(
            animateCss.data.classesToRemove, ["some-class", "another-class"]);
      });
    });
    test("should support chaining", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate
            .css()
            .addClass("added-class")
            .removeClass("removed-class")
            .addAnimationClass("temp-class")
            .addClass("another-added-class");
        expect(animateCss.data.classesToAdd,
            ["added-class", "another-added-class"]);
        expect(animateCss.data.classesToRemove, ["removed-class"]);
        expect(animateCss.data.animationClasses, ["temp-class"]);
      });
    });
    test("should support duration and delay", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        animateCss.setDelay(100).setDuration(200);
        expect(animateCss.data.duration, 200);
        expect(animateCss.data.delay, 100);
        var element = el("<div></div>");
        var runner = animateCss.start(element);
        runner.flush();
        if (DOM.supportsAnimation()) {
          expect(runner.computedDelay, 100);
          expect(runner.computedDuration, 200);
        } else {
          expect(runner.computedDelay, 0);
          expect(runner.computedDuration, 0);
        }
      });
    });
    test("should support from styles", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        animateCss.setFromStyles({"backgroundColor": "blue"});
        expect(animateCss.data.fromStyles, isNotNull);
        var element = el("<div></div>");
        animateCss.start(element);
        expect(element.style.getPropertyValue("background-color"), "blue");
      });
    });
    test("should support duration and delay defined in CSS", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css();
        var element = el(
            '''<div style="${ DOM . getAnimationPrefix ( )}transition: 0.5s ease 250ms;"></div>''');
        var runner = animateCss.start(element);
        runner.flush();
        if (DOM.supportsAnimation()) {
          expect(runner.computedDelay, 250);
          expect(runner.computedDuration, 500);
        } else {
          expect(runner.computedDelay, 0);
          expect(runner.computedDuration, 0);
        }
      });
    });
    test("should add classes", () async {
      return inject([AnimationBuilder], (animate) {
        var animateCss = animate.css().addClass("one").addClass("two");
        var element = el("<div></div>");
        var runner = animateCss.start(element);
        expect(!element.classes.contains("one"), isTrue);
        expect(!element.classes.contains("two"), isTrue);
        runner.flush();
        expect(element.classes.contains("one"), isTrue);
        expect(element.classes.contains("two"), isTrue);
      });
    });
    test("should call `onComplete` method after animations have finished",
        () async {
      return inject([AnimationBuilder], (animate) {
        bool animationFinished = false;
        var runner = animate
            .css()
            .addClass("one")
            .addClass("two")
            .setDuration(100)
            .start(el("<div></div>"))
            .onComplete(() => animationFinished = true);
        expect(animationFinished, isFalse);
        runner.flush();
        if (DOM.supportsAnimation()) {
          expect(animationFinished, isFalse);
          runner.handleAnimationCompleted();
          expect(animationFinished, isTrue);
        } else {
          expect(animationFinished, isTrue);
        }
      });
    });
  });
}
