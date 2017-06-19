class CompilerConfig {
  /// [true] if compiler is generating development binary.
  final bool genDebugInfo;

  /// If [true], generates code to show binding values inside live DOM for
  /// debugging.
  final bool logBindingUpdate;

  /// If [true], shadow host selectors prevent following selectors from being
  /// scoped to their component much like a shadow piercing combinator. It
  /// also allows the use of the following deprecated selectors:
  /// * ::content
  /// * ::shadow
  /// * polyfill-next-selector
  /// * polyfill-unscoped-rule
  final bool useLegacyStyleEncapsulation;

  /// Performance profiling mode to generates code for component and
  /// binding performance.
  final ProfileType profileType;

  CompilerConfig({
    this.genDebugInfo: false,
    this.logBindingUpdate: false,
    this.useLegacyStyleEncapsulation: false,
    this.profileType: ProfileType.None,
  });
}

enum ProfileType {
  /// No profiling.
  None,

  /// Profile component view construction performance.
  Build,

  /// Profile component bindings (getters in component).
  Binding
}

/// Converts codegen_mode build option to profiler type.
ProfileType codegenModeToProfileType(String codeGenMode) {
  switch (codeGenMode) {
    case 'profile':
      return ProfileType.Build;
    case 'profilebind':
      return ProfileType.Binding;
  }
  return ProfileType.None;
}
