import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors' as m;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/source/pub_package_map_provider.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart' show DartSdk;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:cli_util/cli_util.dart' as cli;
import 'package:path/path.dart' as p;

import 'package:test/test.dart';

final Uri _thisFileUri =
    (m.reflect(getLibraries) as m.ClosureMirror).function.location.sourceUri;

/// This is the path to the root of the `angular` package.
///
/// The call to `resolve` navigates relative to **this** file.
final String _dotPackagesPath =
    _thisFileUri.resolve('../.packages').toFilePath();

/// This is the path to the root of the `angular` package.
///
/// The call to `resolve` navigates relative to **this** file.
final String _packageRootPath =
    _thisFileUri.resolve('../../angular').toFilePath();

int _uriComparer(Uri a, Uri b) => a.toString().compareTo(b.toString());

Set<String> getMembers(LibraryElement libElement) {
  var elements = new SplayTreeSet<String>();

  elements.addAll(libElement.definingCompilationUnit.types
      .where((ce) => ce.isPublic)
      .map((ce) => ce.name));

  var exportedNamespace =
      new NamespaceBuilder().createExportNamespaceForLibrary(libElement);

  elements.addAll(exportedNamespace.definedNames.keys);

  return elements;
}

Future<Map<String, LibraryElement>> getLibraries() async {
  var pkgLibPath = p.join(_packageRootPath, 'lib');

  var result = Process.runSync('find', [pkgLibPath, '-iname', '*.dart']);

  var items = LineSplitter.split(result.stdout).toSet();

  // only things in lib (but not lib/src)
  items.removeWhere((path) {
    var relativePath = p.relative(path, from: pkgLibPath);
    var segments = p.split(relativePath);
    return segments.length > 1 && segments.first == 'src';
  });

  var context = await _getAnalysisContextForProjectPath(
      _dotPackagesPath, _packageRootPath, items);

  var uriSources = new SplayTreeMap<Uri, Source>(_uriComparer);
  var libElements = new SplayTreeMap<String, LibraryElement>();

  for (var source in context.librarySources) {
    if (source.uri.scheme != 'file') {
      continue;
    }
    var filePath = source.uri.toFilePath();
    if (!items.contains(filePath)) {
      continue;
    }
    uriSources[source.uri] = source;

    var lib = context.getLibraryElement(source);
    expect(lib, isNotNull, reason: 'For ${source.uri}');

    libElements[p.relative(filePath, from: pkgLibPath)] = lib;
  }

  expect(uriSources, hasLength(items.length));

  return libElements;
}

/// [foundFiles] is the list of files to consider for the context.
Future<AnalysisContext> _getAnalysisContextForProjectPath(
    String dotPackagesPath,
    String projectPath,
    Iterable<String> foundFiles) async {
  // TODO: fail more clearly if this...fails
  var sdkPath = cli.getSdkDir().path;

  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  DartSdk sdk = new FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(sdkPath));

  var packageResolver = _getPackageResolver(dotPackagesPath, sdk);

  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(PhysicalResourceProvider.INSTANCE),
    packageResolver
  ];

  AnalysisEngine.instance.processRequiredPlugins();

  var options = new AnalysisOptionsImpl()..analyzeFunctionBodies = false;

  var context = AnalysisEngine.instance.createAnalysisContext()
    ..analysisOptions = options
    ..sourceFactory = new SourceFactory(resolvers);

  // ensures all libraries defined by the set of files are resolved
  _getLibraryElements(foundFiles, context).toList();

  return context;
}

UriResolver _getPackageResolver(String dotPackagesPath, DartSdk sdk) {
  if (!FileSystemEntity.isFileSync(dotPackagesPath)) {
    throw new StateError('A package configuration file was not found at the '
        'expectetd location. $dotPackagesPath');
  }

  var pubPackageMapProvider =
      new PubPackageMapProvider(PhysicalResourceProvider.INSTANCE, sdk);
  var packageMapInfo = pubPackageMapProvider
      .computePackageMap(PhysicalResourceProvider.INSTANCE.getResource('.'));
  var packageMap = packageMapInfo.packageMap;
  if (packageMap == null) {
    throw new StateError('An error occurred getting the package map.');
  }

  return new PackageMapUriResolver(
      PhysicalResourceProvider.INSTANCE, packageMap);
}

// may return `null` if [path] doesn't refer to a library.
/// [dartFiles] is an [Iterable] of paths to [.dart] files.
Iterable<LibraryElement> _getLibraryElements(
        Iterable<String> dartFiles, AnalysisContext context) =>
    dartFiles
        .map((path) => _getLibraryElement(path, context))
        .where((lib) => lib != null);

LibraryElement _getLibraryElement(String path, AnalysisContext context) {
  Source source = new FileBasedSource(new JavaFile(path));
  if (context.computeKindOf(source) == SourceKind.LIBRARY) {
    return context.computeLibraryElement(source);
  }
  return null;
}
