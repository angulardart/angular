// Shared constants between profiler codegen and profiler runtime.
// We can't include this from runtime in codegen since runtime uses dart:html.
const String profilerExternalName = 'ng.profiler.metrics';
const String profileCategoryBuild = 'build';
const String profileCategoryChangeDetection = 'cd';
