@JS()
library browser.testability;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:angular/src/core/testability/testability.dart';
import 'package:angular/src/runtime.dart';
import 'package:angular/src/testability/js_api.dart';

@JS('self')
external get _self;

class BrowserGetTestability implements GetTestability {
  const BrowserGetTestability();

  void addToWindow(TestabilityRegistry registry) {
    var jsRegistry = js_util.getProperty(_self, 'ngTestabilityRegistries');
    if (jsRegistry == null) {
      js_util.setProperty(_self, 'ngTestabilityRegistries', jsRegistry = []);
      js_util.setProperty(_self, 'getAngularTestability',
          allowInterop((Element elem, [bool findInAncestors = true]) {
        List<dynamic> registry =
            unsafeCast(js_util.getProperty(_self, 'ngTestabilityRegistries'));
        for (int i = 0; i < registry.length; i++) {
          var result =
              js_util.callMethod(registry[i], 'getAngularTestability', [elem]);
          if (result != null) return result;
        }
        throw StateError('Could not find testability for element.');
      }));
      var getAllAngularTestabilities = () {
        List<dynamic> registry =
            unsafeCast(js_util.getProperty(_self, 'ngTestabilityRegistries'));
        var result = [];
        for (int i = 0; i < registry.length; i++) {
          var testabilities =
              js_util.callMethod(registry[i], 'getAllAngularTestabilities', []);

          // We can't rely on testabilities being a Dart List, since it's read
          // from a JS variable. It might have been created from DDC.
          // Therefore, we only assume that it supports .length and [] access.
          var testabilityCount = js_util.getProperty(testabilities, 'length');
          // ignore: argument_type_not_assignable
          for (var j = 0; j < testabilityCount; j++) {
            var testability = js_util.getProperty(testabilities, j);
            result.add(testability);
          }
        }
        return result;
      };
      js_util.setProperty(_self, 'getAllAngularTestabilities',
          allowInterop(getAllAngularTestabilities));

      var whenAllStable = allowInterop((callback) {
        var testabilities = getAllAngularTestabilities();
        var count = testabilities.length;
        var didWork = false;
        var decrement = (bool didWork_) {
          didWork = didWork || didWork_;
          count--;
          if (count == 0) {
            callback(didWork);
          }
        };
        for (var testability in testabilities) {
          js_util
              .callMethod(testability, 'whenStable', [allowInterop(decrement)]);
        }
      });
      // ignore: non_bool_negation_expression
      if (!js_util.hasProperty(_self, 'frameworkStabilizers')) {
        js_util.setProperty(_self, 'frameworkStabilizers', []);
      }
      js_util.getProperty(_self, 'frameworkStabilizers').add(whenAllStable);
    }
    jsRegistry.add(this._createRegistry(registry));
  }

  Testability findTestabilityInTree(
      TestabilityRegistry registry, Element element) {
    if (element == null) {
      return null;
    }
    return registry.getTestability(element) ??
        findTestabilityInTree(registry, element.parent);
  }

  dynamic _createRegistry(TestabilityRegistry registry) {
    var object = js_util.newObject();
    js_util.setProperty(object, 'getAngularTestability',
        allowInterop((Element element) {
      var testability = registry.findTestabilityInTree(element);
      return testability == null
          ? null
          : JsTestability(
              isStable: allowInterop(testability.isStable),
              whenStable: allowInterop(testability.whenStable));
    }));
    js_util.setProperty(object, 'getAllAngularTestabilities', allowInterop(() {
      var publicTestabilities = registry
          .getAllTestabilities()
          .map((t) => JsTestability(
              isStable: allowInterop(t.isStable),
              whenStable: allowInterop(t.whenStable)))
          .toList();
      return publicTestabilities;
    }));
    return object;
  }
}
