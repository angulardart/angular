import "compile_metadata.dart" show CompileIdentifierMetadata;
import "identifiers.dart" show Identifiers;

class CompilerConfig {
  final bool genDebugInfo;
  final bool logBindingUpdate;
  final bool useJit;
  RenderTypes renderTypes;
  CompilerConfig(this.genDebugInfo, this.logBindingUpdate, this.useJit,
      [RenderTypes renderTypes = null]) {
    if (renderTypes == null) {
      renderTypes = new DefaultRenderTypes();
    }
    this.renderTypes = renderTypes;
  }
}

/// Types used for the renderer.
/// Can be replaced to specialize the generated output to a specific renderer
/// to help tree shaking.
abstract class RenderTypes {
  CompileIdentifierMetadata get renderer;

  CompileIdentifierMetadata get renderText;

  CompileIdentifierMetadata get renderElement;

  CompileIdentifierMetadata get renderComment;

  CompileIdentifierMetadata get renderNode;

  CompileIdentifierMetadata get renderEvent;
}

class DefaultRenderTypes implements RenderTypes {
  var renderer = Identifiers.Renderer;
  var renderText;
  var renderElement;
  var renderComment;
  var renderNode;
  var renderEvent;
}
