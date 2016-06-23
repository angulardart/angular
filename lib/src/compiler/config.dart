library angular2.src.compiler.config;

import "package:angular2/src/facade/lang.dart" show isBlank;
import "package:angular2/src/facade/exceptions.dart" show unimplemented;
import "identifiers.dart" show Identifiers;
import "compile_metadata.dart" show CompileIdentifierMetadata;

class CompilerConfig {
  bool genDebugInfo;
  bool logBindingUpdate;
  bool useJit;
  RenderTypes renderTypes;
  CompilerConfig(this.genDebugInfo, this.logBindingUpdate, this.useJit,
      [RenderTypes renderTypes = null]) {
    if (isBlank(renderTypes)) {
      renderTypes = new DefaultRenderTypes();
    }
    this.renderTypes = renderTypes;
  }
}

/**
 * Types used for the renderer.
 * Can be replaced to specialize the generated output to a specific renderer
 * to help tree shaking.
 */
abstract class RenderTypes {
  CompileIdentifierMetadata get renderer {
    return unimplemented();
  }

  CompileIdentifierMetadata get renderText {
    return unimplemented();
  }

  CompileIdentifierMetadata get renderElement {
    return unimplemented();
  }

  CompileIdentifierMetadata get renderComment {
    return unimplemented();
  }

  CompileIdentifierMetadata get renderNode {
    return unimplemented();
  }

  CompileIdentifierMetadata get renderEvent {
    return unimplemented();
  }
}

class DefaultRenderTypes implements RenderTypes {
  var renderer = Identifiers.Renderer;
  var renderText = null;
  var renderElement = null;
  var renderComment = null;
  var renderNode = null;
  var renderEvent = null;
}
