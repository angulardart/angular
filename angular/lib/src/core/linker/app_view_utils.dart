import 'dart:html' show DocumentFragment, NodeTreeSanitizer;

import 'package:angular/di.dart' show Injectable;
import 'package:angular/src/core/application_tokens.dart' show APP_ID;
import 'package:angular/src/core/linker/template_ref.dart';
import 'package:angular/src/core/linker/view_container.dart';
import 'package:angular/src/security/sanitization_service.dart';
import 'package:angular/src/runtime/dom_events.dart' show EventManager;

/// Application wide view utilities.
AppViewUtils appViewUtils;

/// Utilities to create unique RenderComponentType instances for AppViews and
/// provide access to root dom renderer.
@Injectable()
class AppViewUtils {
  final String appId;
  final EventManager eventManager;
  final SanitizationService sanitizer;

  const AppViewUtils(
    @APP_ID this.appId,
    this.sanitizer,
    this.eventManager,
  );
}

/// Creates a document fragment from [trustedHtml].
DocumentFragment createTrustedHtml(String trustedHtml) {
  return DocumentFragment.html(
    trustedHtml,
    treeSanitizer: NodeTreeSanitizer.trusted,
  );
}

/// Loads Dart code used in [templateRef] lazily.
///
/// Returns a function, that when executed, cancels the creation of the view.
void Function() loadDeferred(
  Future<void> Function() loadComponent,
  Future<void> Function() loadTemplateLib,
  ViewContainer viewContainer,
  TemplateRef templateRef,
) {
  var cancelled = false;
  Future.wait([loadComponent(), loadTemplateLib()]).then((_) {
    if (!cancelled) {
      viewContainer.createEmbeddedView(templateRef);
      viewContainer.detectChangesInNestedViews();
    }
  });
  return () {
    cancelled = true;
  };
}
