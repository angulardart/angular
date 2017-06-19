import 'dart:html';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'profile_keys.dart';

/// Array of profile ids of the form  category:component:viewIndex.
final List<String> profileIds = <String>[];

/// Trace type + raw high resolution performance timing data.
final List<num> profileData = <num>[];

bool profileProbeInstalled = false;

/// Called by component at runtime to start profiling.
///
/// Functions in this library are only referenced by template.dart files
/// if user has specified
///     --define=NG_CODEGEN_ARGS=codegen_mode=profile for bazel
///     or codegen_mode: profile in pubspec.
void profileSetup() {
  if (!profileProbeInstalled) {
    profileProbeInstalled = true;
    // Setup Console profiler object. So users can write out
    // collected profile metrics as CSV.
    _setGlobalVar(profilerExternalName, _inspectProfile);
  }
}

/// Aggregate collected data and write out CSV to browser console.
void _inspectProfile() {
  int logCount = profileIds.length;
  _PerfProfile profile = new _PerfProfile();
  for (int i = 0, iData = 0; i < logCount; i++, iData += 2) {
    profile.add(profileIds[i], profileData[iData], profileData[iData + 1]);
  }
  profile.printTotal();
}

/// Setup javascript object to access functions in REPL.
void _setGlobalVar(String path, value) {
  var parts = path.split('.');
  Object obj = window;
  for (var i = 0; i < parts.length - 1; i++) {
    var name = parts[i];
    if (!js_util.callMethod(obj, 'hasOwnProperty', [name])) {
      js_util.setProperty(obj, name, js_util.newObject());
    }
    obj = js_util.getProperty(obj, name);
  }
  js_util.setProperty(obj, parts[parts.length - 1],
      (value is Function) ? js.allowInterop(value) : value);
}

/// Called at runtime to start logging timing data.
void profileMarkStart(String profileId) {
  profileIds.add(profileId);
  profileData.add(_ProfileData.typeMarkStart);
  profileData.add(window.performance.now());
}

/// Called at runtime to mark the end of profile data.
void profileMarkEnd(String profileId) {
  var ts = window.performance.now();
  profileIds.add(profileId);
  profileData.add(_ProfileData.typeMarkEnd);
  profileData.add(ts);
}

/// Aggregated metrics for a single Angular component.
class _ComponentMetrics {
  final String name;
  num buildTime = 0.0;
  num childTime = 0.0;
  num changeDetectTime = 0.0;
  int count = 0;

  _ComponentMetrics(this.name);

  num get totalTime => buildTime + changeDetectTime;
  num get selfTime => buildTime + changeDetectTime - childTime;
}

/// Builds up hierarchical ranges of profile data and aggregates metrics.
class _PerfProfile {
  /// Original captured data.
  final log = <_ProfileData>[];

  /// Maps from profile name to aggregate duration.
  void add(String key, num type, num ts) {
    var keys = key.split(':');
    log.add(new _ProfileData(
        key, keys[0], keys[1], keys.length > 2 ? keys[2] : '', type, ts));
  }

  void printTotal() {
    final componentMetrics = <String, _ComponentMetrics>{};
    final startTime = <String, List<_ProfileData>>{};
    for (_ProfileData data in log) {
      //print('${data.name} \t Type: ${data.type} ${data.ts}');
      if (data.type == _ProfileData.typeMarkStart) {
        List<_ProfileData> startList = startTime[data.key];
        startList ??= startTime[data.key] = [];
        startList.add(data);
        continue;
      } else if (data.type == _ProfileData.typeMarkEnd) {
        _ProfileData start = startTime[data.key].last;
        if (start != null) {
          startTime[data.key].removeLast();
          start.duration = data.ts - start.ts;
          data.startMarker = start;
        }
      }
    }

    // Compute self time.
    final activeComponents = <_ProfileData>[];
    for (_ProfileData data in log) {
      if (data.type == _ProfileData.typeMarkStart) {
        activeComponents.add(data);
      } else if (data.type == _ProfileData.typeMarkEnd) {
        /// End marker -> remove last active instance.
        for (int i = activeComponents.length - 1; i >= 0; i--) {
          if (activeComponents[i].key == data.key) {
            if (i > 0) {
              _ProfileData parent = activeComponents[i - 1];
              final startMarker = data.startMarker;
              //print('${data.ts}>=${parent.ts}  ${(data.ts + data.duration)} < ${(parent.ts + parent.duration)} adding: ${data.duration}');
              if (startMarker.ts >= parent.ts &&
                  (startMarker.ts + startMarker.duration) <
                      (parent.ts + parent.duration)) {
                parent.childTime += startMarker.duration;
              }
            }
            activeComponents.removeAt(i);
            break;
          }
        }
      }
    }

    // Compute total time by component name.
    for (_ProfileData data in log) {
      if (data.type != _ProfileData.typeMarkStart) continue;
      _ComponentMetrics metrics = componentMetrics[data.name] ??
          (componentMetrics[data.name] = new _ComponentMetrics(data.name));
      switch (data.category) {
        case profileCategoryBuild:
          metrics.buildTime += data.duration;
          if (data.subView == '0') {
            metrics.count++;
          }
          break;
        case profileCategoryChangeDetection:
          metrics.changeDetectTime += data.duration;
          break;
      }
      metrics.childTime += data.childTime;
    }

    if (activeComponents.isNotEmpty) {
      throw new Exception('Corrupt data');
    }

    print(aggregatedMetricsAsCsv(componentMetrics));
  }

  String aggregatedMetricsAsCsv(
      Map<String, _ComponentMetrics> componentMetrics) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('Component,Total,Self,Count,Build,Change');
    for (_ComponentMetrics metrics in componentMetrics.values) {
      sb.writeln('${metrics.name},${metrics.totalTime.toStringAsPrecision(3)}'
          ',${metrics.selfTime.toStringAsPrecision(3)}'
          ',${metrics.count}'
          ',${metrics.buildTime.toStringAsPrecision(3)}'
          ',${metrics.changeDetectTime.toStringAsPrecision(3)}');
    }
    return sb.toString();
  }
}

// Temporary per trace data for a unique key.
class _ProfileData {
  static const num typeMarkStart = 0;
  static const num typeMarkEnd = 1;
  final String category;
  final String key;
  final String name;
  final String subView;
  final num type;
  // Time stamp.
  final num ts;
  // A reference to start marker for each end markers.
  _ProfileData startMarker;
  num childTime = 0;
  num duration = 0;

  _ProfileData(
      this.key, this.category, this.name, this.subView, this.type, this.ts);
}
