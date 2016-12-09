class CompilerConfig {
  /// [true] if compiler is generating development binary.
  final bool genDebugInfo;

  /// If [true], generates code to show binding values inside live DOM for
  /// debugging.
  final bool logBindingUpdate;

  CompilerConfig(this.genDebugInfo, this.logBindingUpdate);
}
