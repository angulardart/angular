import 'dart:async';

import 'package:analyzer/src/summary/api_signature.dart';
import 'package:angular_analyzer_plugin/src/options.dart';

/// Hashing required for the [FileTracker] to be able to compute signatures.
abstract class FileHasher {
  ApiSignature getContentHash(String path);
  Future<String> getUnitElementSignature(String path);
}

/// Compute signatures and relationships between dart summaries & html contents.
///
/// We can use the signatures to cache analysis results, just like the Dart
/// driver does. We also want to be able to discover the relationships between
/// Dart and HTML files so that when an HTML file is updated, we can efficiently
/// reanalyze only the dart files that are affected.
///
/// Note that Dart files depend on HTML files when a Dart component imports
/// another Dart component which may have `<ng-content>` tags in its template,
/// which affect that secondary component's API.
///
/// Also note that the Dart analyzer package does not expose file dependency
/// tracking. Currently, if a Dart file is altered, we reanalyze everything
/// rather than just dependent files. In practice this works well because
/// users don't do code completion with the plugin there and so latency there is
/// less important, and avoiding a cache increases correctness guarantees.
class FileTracker {
  /// Define a salt to invalidate all hashes on new feature additions etc.
  static const int salt = 6;

  final FileHasher _fileHasher;
  final AngularOptions _options;

  final _dartToDart = _RelationshipTracker();

  final _dartToHtml = _RelationshipTracker();
  final _dartFilesWithDartTemplates = <String>{};

  /// Cache the hashes of files for quicker signature calculation.
  final contentHashes = <String, _FileHash>{};

  FileTracker(this._fileHasher, this._options);

  /// Add tag names to the signature. Note: in the future when there are more
  /// lists of strings in options to add, we must be careful that they are
  /// properly delimited/differentiated!
  void addCustomEvents(ApiSignature signature) {
    final hashString = _options.customEventsHashString;
    if (hashString != null && hashString.isNotEmpty) {
      signature.addString(hashString);
    }
  }

  /// Add tag names to the signature. Note: in the future when there are more
  /// lists of strings in options to add, we must be careful that they are
  /// properly delimited/differentiated!
  void addTags(ApiSignature signature) {
    for (final tagname in _options.customTagNames) {
      signature.addString('t:$tagname');
    }
  }

  /// Get a content signature for a [path].
  ApiSignature getContentSignature(String path) {
    if (contentHashes[path] == null) {
      rehashContents(path);
    }
    return contentHashes[path].saltedSignature;
  }

  /// Find Dart sources affected by an HTML change that need reanalysis.
  ///
  /// This is used to reanalyze the correct Dart files when HTML files are
  /// updated.
  List<String> getDartPathsAffectedByHtml(String htmlPath) => _dartToHtml
      .getFilesReferencingFile(htmlPath)
      .map(_dartToDart.getFilesReferencingFile)
      .fold<List<String>>(<String>[], (list, acc) => list..addAll(acc))
      .where(_dartFilesWithDartTemplates.contains)
      .toList();

  /// Find Dart sources that refer directly to [htmlPath].
  ///
  /// This is used to be able to analyze [htmlPath], where we need to know which
  /// components reference that [htmlPath].
  List<String> getDartPathsReferencingHtml(String htmlPath) =>
      _dartToHtml.getFilesReferencingFile(htmlPath);

  /// Get the signature for a Dart file, including its Dart and HTML deps.
  ///
  /// This is used to cache analysis results for a Dart file, and must contain
  /// hashes of all the information that contributed to that analysis.
  Future<ApiSignature> getDartSignature(String dartPath) async {
    final signature = await getUnitElementSignature(dartPath);
    for (final htmlPath in getHtmlPathsAffectingDart(dartPath)) {
      signature.addBytes(_getContentHash(htmlPath));
    }

    // Note, options which affect ng-content extraction should not be hashed
    // here. Those should be hashed into ContentSignature.
    addTags(signature);
    addCustomEvents(signature);

    return signature;
  }

  /// Get the HTML files that affect a Dart file at [dartPath].
  ///
  /// This occurs when, for instance, a main component with an inline template
  /// imports a secondary component with a templateUrl. That main component's
  /// template string must be analyzed against the latest version of the
  /// secondary HTML, which may define `<ng-content>`s that affect the result.
  ///
  /// This is used to know when Dart files have to be reanalyzed when an HTML
  /// file is updated.
  List<String> getHtmlPathsAffectingDart(String dartPath) {
    if (_dartFilesWithDartTemplates.contains(dartPath)) {
      return getHtmlPathsAffectingDartContext(dartPath);
    }

    return [];
  }

  /// Get the HTML files that affect APIs of components defined in [dartPath].
  ///
  /// This is used to by [getDartSignature] and [getHtmlSignature] to ensure
  /// that Dart result signatures include the signatures of all HTML files that
  /// affected that result.
  List<String> getHtmlPathsAffectingDartContext(String dartPath) => _dartToDart
      .getFilesReferencedBy(dartPath)
      .map(_dartToHtml.getFilesReferencedBy)
      .fold<List<String>>(
          <String>[], (list, acc) => list..addAll(acc)).toList();

  /// Get the HTML files that are directly referenced by Dart file [dartPath].
  List<String> getHtmlPathsReferencedByDart(String dartPath) =>
      _dartToHtml.getFilesReferencedBy(dartPath);

  /// Get the HTML files that depend on the state of [htmlPath].
  ///
  /// This occurs when, for instance, a main component with a templateUrl
  /// imports a secondary component with a templateUrl. That main component's
  /// template HTML file must be analyzed against the latest version of the
  /// secondary HTML, which may define `<ng-content>`s that affect the result.
  ///
  /// This is used to efficiently reanalyze the HTML files that need to be
  /// reanalyzed when other HTML files are updated.
  List<String> getHtmlPathsReferencingHtml(String htmlPath) => _dartToHtml
      .getFilesReferencingFile(htmlPath)
      .map(_dartToDart.getFilesReferencingFile)
      .fold<List<String>>(<String>[], (list, acc) => list..addAll(acc))
      .map(_dartToHtml.getFilesReferencedBy)
      .fold<List<String>>(<String>[], (list, acc) => list..addAll(acc))
      .toList();

  /// Get the signature for an HTML file, including its Dart and HTML deps.
  ///
  /// This is used to cache analysis results for an HTML file, and must contain
  /// hashes of all the information that contributed to that analysis.
  Future<ApiSignature> getHtmlSignature(String htmlPath) async {
    final signature = ApiSignature()
      ..addInt(salt)
      ..addBytes(_getContentHash(htmlPath));
    for (final dartPath in getDartPathsReferencingHtml(htmlPath)) {
      signature.addString(await _fileHasher.getUnitElementSignature(dartPath));
      for (final subHtmlPath in getHtmlPathsAffectingDartContext(dartPath)) {
        signature.addBytes(_getContentHash(subHtmlPath));
      }
    }

    // Note, options which affect directive/view extraction should not be hashed
    // here. Those should probably be hashed into ElementSignature.
    addTags(signature);
    addCustomEvents(signature);

    return signature;
  }

  /// Get a salted unit element signature for a dart [path].
  Future<ApiSignature> getUnitElementSignature(String path) async =>
      ApiSignature()
        ..addInt(salt)
        ..addString(await _fileHasher.getUnitElementSignature(path));

  /// Trigger a rehash of the contents at [path], which is then cached.
  void rehashContents(String path) {
    final signature = _fileHasher.getContentHash(path);
    final bytes = signature.toByteList();
    contentHashes[path] = _FileHash(
        bytes,
        ApiSignature()
          ..addInt(salt)
          ..addBytes(bytes));
  }

  /// Note that the latset version of [dartPath] has an inline template or not.
  void setDartHasTemplate(String dartPath, bool hasTemplate) {
    if (hasTemplate) {
      _dartFilesWithDartTemplates.add(dartPath);
    } else {
      _dartFilesWithDartTemplates.remove(dartPath);
    }
  }

  /// Note that the latest version of [dartPath] refers to [htmlPaths].
  void setDartHtmlTemplates(String dartPath, List<String> htmlPaths) =>
      _dartToHtml.setFileReferencesFiles(dartPath, htmlPaths);

  /// Note that the latest version of [dartPath] refers to [imports].
  void setDartImports(String dartPath, List<String> imports) {
    _dartToDart.setFileReferencesFiles(dartPath, imports);
  }

  List<int> _getContentHash(String path) {
    if (contentHashes[path] == null) {
      rehashContents(path);
    }
    return contentHashes[path].unsaltedBytes;
  }
}

class _FileHash {
  final List<int> unsaltedBytes;
  final ApiSignature saltedSignature;

  _FileHash(this.unsaltedBytes, this.saltedSignature);
}

class _RelationshipTracker {
  final _filesReferencedByFile = <String, List<String>>{};
  final _filesReferencingFile = <String, List<String>>{};

  List<String> getFilesReferencedBy(String filePath) =>
      _filesReferencedByFile[filePath] ?? [];

  List<String> getFilesReferencingFile(String usesPath) =>
      _filesReferencingFile[usesPath] ?? [];

  void setFileReferencesFiles(String filePath, List<String> referencesPaths) {
    final priorRelationships = <String>{};
    if (_filesReferencedByFile.containsKey(filePath)) {
      for (final referencesPath in _filesReferencedByFile[filePath]) {
        if (!referencesPaths.contains(referencesPath)) {
          _filesReferencingFile[referencesPath].remove(filePath);
        } else {
          priorRelationships.add(referencesPath);
        }
      }
    }

    _filesReferencedByFile[filePath] = referencesPaths;

    for (final referencesPath in referencesPaths) {
      if (priorRelationships.contains(referencesPath)) {
        continue;
      }

      if (!_filesReferencingFile.containsKey(referencesPath)) {
        _filesReferencingFile[referencesPath] = [filePath];
      } else {
        _filesReferencingFile[referencesPath].add(filePath);
      }
    }
  }
}
