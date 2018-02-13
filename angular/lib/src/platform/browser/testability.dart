@JS()
library browser.testability;

import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:angular/src/core/testability/testability.dart';

@JS('self')
external get _self;

class PublicTestability {
  Testability _testability;
  PublicTestability(Testability testability) {
    this._testability = testability;
  }

  bool isStable() {
    return this._testability.isStable();
  }

  void whenStable(Function callback) {
    this._testability.whenStable(callback);
  }

  List findBindings(Element elem, [String binding, bool exactMatch]) {
    return this._testability.findBindings(elem, binding, exactMatch);
  }

  _toJsObject() {
    return js_util.jsify({
      'findBindings': allowInterop(findBindings),
      'isStable': allowInterop(isStable),
      'whenStable': allowInterop(whenStable),
      '_dart_': this
    });
  }
}

class BrowserGetTestability implements GetTestability {
  const BrowserGetTestability();

  void addToWindow(TestabilityRegistry registry) {
    var jsRegistry = js_util.getProperty(_self, 'ngTestabilityRegistries');
    if (jsRegistry == null) {
      js_util.setProperty(_self, 'ngTestabilityRegistries', jsRegistry = []);
      js_util.setProperty(_self, 'getAngularTestability',
          allowInterop((Element elem, [bool findInAncestors = true]) {
        List registry = js_util.getProperty(_self, 'ngTestabilityRegistries');
        for (int i = 0; i < registry.length; i++) {
          var result = js_util.callMethod(
              registry[i], 'getAngularTestability', [elem, findInAncestors]);
          if (result != null) return result;
        }
        throw new StateError('Could not find testability for element.');
      }));
      var getAllAngularTestabilities = () {
        List registry = js_util.getProperty(_self, 'ngTestabilityRegistries');
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
      TestabilityRegistry registry, dynamic elem, bool findInAncestors) {
    if (elem == null) {
      return null;
    }
    var t = registry.getTestability(elem);
    if (t != null) {
      return t;
    } else if (!findInAncestors) {
      return null;
    }
    if (elem is ShadowRoot) {
      return this.findTestabilityInTree(registry, elem.host, true);
    }
    return this
        .findTestabilityInTree(registry, (elem as Node).parentNode, true);
  }

  dynamic _createRegistry(TestabilityRegistry registry) {
    var object = js_util.newObject();
    js_util.setProperty(object, 'getAngularTestability',
        allowInterop((Element elem, bool findInAncestors) {
      var testability = registry.findTestabilityInTree(elem, findInAncestors);
      return testability == null
          ? null
          : new PublicTestability(testability)._toJsObject();
    }));
    js_util.setProperty(object, 'getAllAngularTestabilities', allowInterop(() {
      var publicTestabilities = registry
          .getAllTestabilities()
          .map((t) => new PublicTestability(t)._toJsObject())
          .toList();
      return publicTestabilities;
    }));
    return object;
  }
}
