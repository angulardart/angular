class SourceModule {
  final String moduleUrl;
  final String source;

  /// Maps a moduleUrl to a library prefix. Deferred modules have defer###
  /// prefixes. The moduleUrl has asset: scheme or is a relative url.
  /// This map is used to write out the final import statements and to
  /// skip initReflector calls.
  final Map<String, String> deferredModules;
  SourceModule(this.moduleUrl, this.source, this.deferredModules);
}
