import "package:angular2/src/platform/browser/xhr_impl.dart" show XHRImpl;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DomAdapter;

/// Provides DOM operations in any browser environment.
abstract class GenericBrowserDomAdapter<T, N, ET> extends DomAdapter<T, N, ET> {
  String _animationPrefix = null;
  String _transitionEnd = null;
  GenericBrowserDomAdapter() : super() {
    // Detect animationFrame and end of transition function names.
    try {
      T element = this.createElement("div", this.defaultDoc());
      if (getStyle(element, "animationName") != null) {
        this._animationPrefix = '';
      } else {
        const domPrefixes = const ["Webkit", "Moz", "O", "ms"];
        for (var i = 0; i < domPrefixes.length; i++) {
          if (getStyle(element, domPrefixes[i] + "AnimationName") != null) {
            _animationPrefix = "-" + domPrefixes[i].toLowerCase() + "-";
            break;
          }
        }
      }
      const List transitionNames = const [
        'WebkitTransition',
        'MozTransition',
        'OTransition',
        'transition'
      ];
      const List transitionEndNames = const [
        'webkitTransitionEnd',
        'transitionend',
        'oTransitionEnd otransitionend',
        'transitionend'
      ];
      for (int i = 0; i < transitionNames.length; i++) {
        String key = transitionNames[i];
        if (getStyle(element, key) != null) {
          this._transitionEnd = transitionEndNames[i];
        }
      }
    } catch (e) {
      _animationPrefix = null;
      _transitionEnd = null;
    }
  }
  Type getXHR() {
    return XHRImpl;
  }

  List<dynamic> getDistributedNodes(dynamic el) {
    return el.getDistributedNodes();
  }

  resolveAndSetHref(dynamic el, String baseUrl, String href) {
    el.href = href == null ? baseUrl : baseUrl + "/../" + href;
  }

  bool supportsDOMEvents() {
    return true;
  }

  bool supportsNativeShadowDOM() =>
      this.defaultDoc().body.createShadowRoot is Function;

  String getAnimationPrefix() => _animationPrefix ?? '';

  String getTransitionEnd() => _transitionEnd ?? '';

  bool supportsAnimation() =>
      _animationPrefix != null && _transitionEnd != null;
}
