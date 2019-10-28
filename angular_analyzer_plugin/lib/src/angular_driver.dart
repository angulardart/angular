import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/api_signature.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:crypto/crypto.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/angular_ast_extraction.dart';
import 'package:angular_analyzer_plugin/src/converter.dart';
import 'package:angular_analyzer_plugin/src/file_tracker.dart';
import 'package:angular_analyzer_plugin/src/from_file_prefixed_error.dart';
import 'package:angular_analyzer_plugin/src/link/directive_provider.dart';
import 'package:angular_analyzer_plugin/src/link/link.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/annotated_class.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/model/syntactic/component.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/model/syntactic/directive_base.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart'
    as syntactic;
import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:angular_analyzer_plugin/src/resolver/template_resolver.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';
import 'package:angular_analyzer_plugin/src/summary/format.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';
import 'package:angular_analyzer_plugin/src/summary/summarize.dart';
import 'package:angular_analyzer_plugin/src/syntactic_discovery.dart';

class AngularDriver
    implements AnalysisDriverGeneric, DirectiveProvider, FileHasher {
  final ResourceProvider _resourceProvider;
  final AnalysisDriverScheduler _scheduler;
  final AnalysisDriver dartDriver;
  final FileContentOverlay contentOverlay;
  final AngularOptions options;
  StandardHtml standardHtml;
  StandardAngular standardAngular;
  SourceFactory _sourceFactory;
  final _addedFiles = <String>{};
  final _dartFiles = <String>{};
  final _changedFiles = <String>{};
  final _requestedDartFiles = <String, List<Completer<DirectivesResult>>>{};
  final _requestedHtmlFiles = <String, List<Completer<DirectivesResult>>>{};
  final _filesToAnalyze = <String>{};
  final _htmlFilesToAnalyze = <String>{};
  final ByteStore byteStore;
  FileTracker _fileTracker;
  final lastSignatures = <String, String>{};
  bool _hasAngularImported = false;
  final completionContributors = <CompletionContributor>[];

  final _dartResultsController = StreamController<DirectivesResult>();

  // ignore: close_sinks
  final _htmlResultsController = StreamController<DirectivesResult>();

  AngularDriver(
      this._resourceProvider,
      this.dartDriver,
      this._scheduler,
      this.byteStore,
      SourceFactory sourceFactory,
      this.contentOverlay,
      this.options) {
    _sourceFactory = sourceFactory;
    _scheduler.add(this);
    _fileTracker = FileTracker(this, options);
    // TODO only support package:angular once we all move to that
    _hasAngularImported =
        _sourceFactory.resolveUri(null, "package:angular/angular.dart") != null;
  }

  @override
  bool get hasFilesToAnalyze =>
      _filesToAnalyze.isNotEmpty ||
      _htmlFilesToAnalyze.isNotEmpty ||
      _requestedDartFiles.isNotEmpty ||
      _requestedHtmlFiles.isNotEmpty;

  // ignore: close_sinks
  Stream<DirectivesResult> get dartResultsStream =>
      _dartResultsController.stream;

  Stream<DirectivesResult> get htmlResultsStream =>
      _htmlResultsController.stream;

  /// Notify the driver that the client is going to stop using it.
  @override
  void dispose() {
    _dartResultsController.close();
    _htmlResultsController.close();
  }

  List<String> get priorityFiles => [];

  /// Set priority files (not supported).
  ///
  /// This is implemented in order to satisfy the [AnalysisDriverGeneric]
  /// interface. Ideally, we analyze these files first. For the moment, this
  /// lets the analysis server team add this method to the interface without
  /// breaking any code.
  @override
  set priorityFiles(List<String> priorityPaths) {
    // TODO analyze these files first
  }

  @override
  void addFile(String path) {
    if (_ownsFile(path)) {
      _addedFiles.add(path);
      if (path.endsWith('.dart')) {
        _dartFiles.add(path);
      }
      fileChanged(path);
    }
  }

  void fileChanged(String path) {
    if (_ownsFile(path)) {
      _fileTracker.rehashContents(path);

      if (path.endsWith('.html')) {
        _htmlFilesToAnalyze.add(path);
        for (final path in _fileTracker.getHtmlPathsReferencingHtml(path)) {
          _htmlFilesToAnalyze.add(path);
        }
        for (final path in _fileTracker.getDartPathsAffectedByHtml(path)) {
          _filesToAnalyze.add(path);
        }
      } else {
        _changedFiles.add(path);
      }
    }
    _scheduler.notify(this);
  }

  @override
  AnalysisDriverPriority get workPriority {
    if (!_hasAngularImported) {
      return AnalysisDriverPriority.nothing;
    }
    if (standardHtml == null) {
      return AnalysisDriverPriority.interactive;
    }
    if (_requestedDartFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_requestedHtmlFiles.isNotEmpty) {
      return AnalysisDriverPriority.interactive;
    }
    if (_filesToAnalyze.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    if (_htmlFilesToAnalyze.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    if (_changedFiles.isNotEmpty) {
      return AnalysisDriverPriority.general;
    }
    return AnalysisDriverPriority.nothing;
  }

  @override
  Future<Null> performWork() async {
    if (standardAngular == null) {
      await buildStandardAngular();
      return;
    }

    if (standardHtml == null) {
      await buildStandardHtml();
      return;
    }

    if (_changedFiles.isNotEmpty) {
      _changedFiles.clear();
      _filesToAnalyze.addAll(_dartFiles);
      return;
    }

    if (_requestedDartFiles.isNotEmpty) {
      final path = _requestedDartFiles.keys.first;
      final completers = _requestedDartFiles.remove(path);
      try {
        final result = await _resolveDart(path,
            onlyIfChangedSignature: false, ignoreCache: true);
        completers.forEach((completer) => completer.complete(result));
      } catch (e, st) {
        completers.forEach((completer) => completer.completeError(e, st));
      }

      return;
    }

    if (_requestedHtmlFiles.isNotEmpty) {
      final path = _requestedHtmlFiles.keys.first;
      final completers = _requestedHtmlFiles.remove(path);
      DirectivesResult result;

      try {
        // Try resolving HTML using the existing dart/html relationships which
        // may be already known. However, if we don't see any relationships, try
        // using the .dart equivalent. Better than no result -- the real one
        // WILL come.
        if (_fileTracker.getDartPathsReferencingHtml(path).isEmpty) {
          result =
              await _resolveHtmlFrom(path, path.replaceAll(".html", ".dart"));
        } else {
          result = await _resolveHtml(path, ignoreCache: true);
        }

        // After whichever resolution is complete, push errors.
        completers.forEach((completer) => completer.complete(result));
      } catch (e, st) {
        completers.forEach((completer) => completer.completeError(e, st));
      }

      return;
    }

    if (_filesToAnalyze.isNotEmpty) {
      final path = _filesToAnalyze.first;
      await _resolveDart(path);
      _filesToAnalyze.remove(path);
      return;
    }

    if (_htmlFilesToAnalyze.isNotEmpty) {
      final path = _htmlFilesToAnalyze.first;
      await _resolveHtml(path);
      _htmlFilesToAnalyze.remove(path);
      return;
    }

    return;
  }

  Future<List<Template>> computeTemplatesForFile(String filePath) async {
    final templates = <Template>[];
    final isDartFile = filePath.endsWith('.dart');
    if (!isDartFile && !filePath.endsWith('.html')) {
      return templates;
    }

    final directiveResults = isDartFile
        ? await requestDartResult(filePath)
        : await requestHtmlResult(filePath);
    final directives = directiveResults.directives;
    if (directives == null) {
      return templates;
    }
    for (var directive in directives) {
      if (directive is Component) {
        final match = isDartFile
            ? directive.source.toString() == filePath
            : directive.templateUrlSource?.fullName == filePath;
        if (match && directive.template != null) {
          templates.add(directive.template);
        }
      }
    }
    return templates;
  }

  @override
  Future<String> getUnitElementSignature(String path) =>
      dartDriver.getUnitElementSignature(path);

  /// Get a fully resolved [DirectivesResult] for this Dart path.
  ///
  /// Warning: slow, resolved ASTs are not cached.
  ///
  /// The result will include resolved directives and components. The components
  /// templates will be included & resolved if defined in the component directly
  /// rather than linking to a different html file.
  Future<DirectivesResult> requestDartResult(String path) {
    final completer = Completer<DirectivesResult>();
    _requestedDartFiles
        .putIfAbsent(path, () => <Completer<DirectivesResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  /// Get a fully resolved [DirectivesResult] for this Dart path.
  ///
  /// Warning: slow, resolved ASTs are not cached.
  ///
  /// The result will include resolved components and their resolved templates
  /// for all components known to link to the [path] via `templateUrl`.
  ///
  /// Note that you may get an empty or incomplete result if dart analysis has
  /// not finished finding all `templateUrl`s.
  Future<DirectivesResult> requestHtmlResult(String path) {
    final completer = Completer<DirectivesResult>();
    _requestedHtmlFiles
        .putIfAbsent(path, () => <Completer<DirectivesResult>>[])
        .add(completer);
    _scheduler.notify(this);
    return completer.future;
  }

  UnlinkedDartSummary _buildUnlinkedAngularTopLevels(String path) {
    final baseKey = _fileTracker.getContentSignature(path).toHex();
    final key = '$baseKey.ngunlinked';
    final bytes = byteStore.get(key);
    if (bytes != null) {
      return UnlinkedDartSummary.fromBuffer(bytes);
    }

    final dartResult = dartDriver.parseFileSync(path);
    if (dartResult == null) {
      return null;
    }

    final ast = dartResult.unit;
    final source = _sourceFor(path);
    final extractor = SyntacticDiscovery(ast, source);
    final topLevels = extractor.discoverTopLevels();
    final errors = List<AnalysisError>.from(extractor.errorListener.errors);
    final summary = summarizeDartResult(topLevels, errors);
    final newBytes = summary.toBuffer();
    byteStore.put(key, newBytes);
    return summary;
  }

  Future<DirectivesResult> _resolveDart(String path,
      {bool ignoreCache = false, bool onlyIfChangedSignature = true}) async {
    // This happens when the path is..."hidden by a generated file"..whch I
    // don't understand, but, can protect against. Should not be analyzed.
    // TODO detect this on file add rather than on file analyze.
    if (await dartDriver.getUnitElementSignature(path) == null) {
      _dartFiles.remove(path);
      return null;
    }

    final baseKey = (await _fileTracker.getUnitElementSignature(path)).toHex();
    final key = '$baseKey.ngresolved';

    if (lastSignatures[path] == key && onlyIfChangedSignature) {
      return null;
    }

    lastSignatures[path] = key;

    if (!ignoreCache) {
      final bytes = byteStore.get(key);
      if (bytes != null) {
        final summary = LinkedDartSummary.fromBuffer(bytes);
        _trackAndHandleFileRelationships(path, summary);
        final result = DirectivesResult.fromCache(
            path, _deserializeErrors(_sourceFor(path), summary.errors));
        _dartResultsController.add(result);
        return result;
      }
    }

    final unit = (await dartDriver.getUnitElement(path)).element;
    if (unit == null) {
      return null;
    }

    final context = unit.context;
    final source = unit.source;

    final unlinkedSummary = _buildUnlinkedAngularTopLevels(path);
    final errorListener = RecordingErrorListener();
    final errorReporter = ErrorReporter(errorListener, _sourceFor(path));
    final linker = EagerLinker(
        context.typeSystem, standardAngular, standardHtml, errorReporter, this);
    final directives = linkTopLevels(unlinkedSummary, unit, linker);
    final pipes = linkPipes(unlinkedSummary.pipeSummaries, unit, linker);

    final errors = _deserializeErrors(source, unlinkedSummary.errors)
      ..addAll(errorListener.errors);

    final htmlViews = <String>[];
    final usesDart = <String>[];
    final fullyResolvedDirectives = <DirectiveBase>[];

    var hasDartTemplate = false;
    for (final directive in directives) {
      if (directive is Component) {
        if ((directive.templateText ?? '') != '') {
          hasDartTemplate = true;
          await _resolveDartTemplateText(directive, source, context, errors);
          fullyResolvedDirectives.add(directive);
        } else if (directive.templateUrlSource != null) {
          htmlViews.add(directive.templateUrlSource.fullName);
        }

        for (final subDirective in directive.directives ?? <Null>[]) {
          usesDart.add(subDirective.source.fullName);
        }
      }
    }

    final summary = LinkedDartSummaryBuilder()
      ..errors = summarizeErrors(errors)
      ..referencedHtmlFiles = htmlViews
      ..referencedDartFiles = usesDart
      ..hasDartTemplates = hasDartTemplate;
    final newBytes = summary.toBuffer();
    byteStore.put(key, newBytes);

    _trackAndHandleFileRelationships(path, summary);
    final directivesResult = DirectivesResult(path, directives, pipes, errors,
        fullyResolvedDirectives: fullyResolvedDirectives);
    _dartResultsController.add(directivesResult);
    return directivesResult;
  }

  /// Update [_fileTracker] relationships and add to [_htmlFilesToAnalyze].
  ///
  /// It's important that when the state of dart files change (either by
  /// analysis or a return to an old cached state), that we update
  /// [_fileTracker] so we know which html and dart files depend on each other.
  /// It's also important that we schedule an analysis of dependent HTML files
  /// (if they are unaffected, we will just pull their state from the cache).
  void _trackAndHandleFileRelationships(
      String path, LinkedDartSummary summary) {
    _fileTracker
      ..setDartHasTemplate(path, summary.hasDartTemplates)
      ..setDartHtmlTemplates(path, summary.referencedHtmlFiles)
      ..setDartImports(path, summary.referencedDartFiles);

    for (final htmlPath in summary.referencedHtmlFiles) {
      _htmlFilesToAnalyze.add(htmlPath);
    }
  }

  Future<void> _resolveDartTemplateText(Component directive, Source source,
      AnalysisContext context, List<AnalysisError> errors) async {
    final tplErrorListener = RecordingErrorListener();
    final errorReporter = ErrorReporter(tplErrorListener, source);

    final tplParser = TemplateParser()
      ..parse(directive.templateText, source,
          offset: directive.templateTextRange.offset);

    final document = tplParser.rawAst;
    final parser = EmbeddedDartParser(source, tplErrorListener, errorReporter);

    final ast = HtmlTreeConverter(parser, source, tplErrorListener)
        .convertFromAstList(tplParser.rawAst)
          ..accept(
              NgContentRecorder(directive.ngContents, source, errorReporter));
    final template = Template(directive, ast);
    directive.template = template;
    setIgnoredErrors(template, document);
    TemplateResolver(
            context.typeProvider,
            context.typeSystem,
            standardHtml.components.values.toList(),
            standardHtml.events,
            standardHtml.attributes,
            await buildStandardAngular(),
            await buildStandardHtml(),
            tplErrorListener,
            options)
        .resolve(template);
    errors
      ..addAll(tplParser.parseErrors
          .where((e) => !template.ignoredErrors.contains(e.errorCode.name)))
      ..addAll(tplErrorListener.errors
          .where((e) => !template.ignoredErrors.contains(e.errorCode.name)));
  }

  Future<DirectivesResult> _resolveHtml(
    String htmlPath, {
    bool ignoreCache = false,
  }) async {
    final key = await _htmlKey(htmlPath);
    final bytes = byteStore.get(key);
    final htmlSource = _sourceFactory.forUri('file:$htmlPath');
    if (!ignoreCache && bytes != null) {
      final summary = LinkedHtmlSummary.fromBuffer(bytes);
      final errors = _deserializeErrors(htmlSource, summary.errors);
      final result = DirectivesResult.fromCache(htmlPath, errors);
      _htmlResultsController.add(result);
      return result;
    }

    final result = DirectivesResult(htmlPath, [], [], []);

    for (final dartContext
        in _fileTracker.getDartPathsReferencingHtml(htmlPath)) {
      final pairResult = await _resolveHtmlFrom(htmlPath, dartContext);
      result.angularTopLevels.addAll(pairResult.angularTopLevels);
      result.errors.addAll(pairResult.errors);
      result.fullyResolvedDirectives.addAll(pairResult.fullyResolvedDirectives);
    }

    final summary = LinkedHtmlSummaryBuilder()
      ..errors = summarizeErrors(result.errors);
    final newBytes = summary.toBuffer();
    byteStore.put(key, newBytes);

    _htmlResultsController.add(result);
    return result;
  }

  Future<DirectivesResult> _resolveHtmlFrom(
      String htmlPath, String dartPath) async {
    final unit = (await dartDriver.getUnitElement(dartPath)).element;

    if (unit == null) {
      return null;
    }

    final htmlSource = _sourceFactory.forUri('file:$htmlPath');
    final dartSource = _sourceFactory.forUri('file:$dartPath');
    final summary = _buildUnlinkedAngularTopLevels(dartPath);
    final linker = EagerLinker(
        unit.context.typeSystem,
        standardAngular,
        standardHtml,
        ErrorReporter(AnalysisErrorListener.NULL_LISTENER, htmlSource),
        this,
        linkHtmlNgContents: false);
    final directives = linkTopLevels(summary, unit, linker);
    final context = unit.context;
    final htmlContent = fileContent(htmlPath);

    final errors = <AnalysisError>[];

    final fullyResolvedDirectives = <DirectiveBase>[];

    for (final directive in directives) {
      if (directive is Component) {
        if (directive.templateUrlSource?.fullName == htmlPath) {
          final tplErrorListener = RecordingErrorListener();
          final errorReporter = ErrorReporter(tplErrorListener, dartSource);

          final tplParser = TemplateParser()..parse(htmlContent, htmlSource);

          final document = tplParser.rawAst;
          final parser =
              EmbeddedDartParser(htmlSource, tplErrorListener, errorReporter);

          final ast = HtmlTreeConverter(parser, htmlSource, tplErrorListener)
              .convertFromAstList(tplParser.rawAst)
                ..accept(NgContentRecorder(
                    directive.ngContents, dartSource, errorReporter));
          final template = Template(directive, ast);
          directive.template = template;
          setIgnoredErrors(template, document);
          TemplateResolver(
                  context.typeProvider,
                  context.typeSystem,
                  standardHtml.components.values.toList(),
                  standardHtml.events,
                  standardHtml.attributes,
                  await buildStandardAngular(),
                  await buildStandardHtml(),
                  tplErrorListener,
                  options)
              .resolve(template);

          bool rightErrorType(AnalysisError e) =>
              !template.ignoredErrors.contains(e.errorCode.name);
          String shorten(String filename) {
            final index = filename.lastIndexOf('.');
            return index == -1 ? filename : filename.substring(0, index);
          }

          errors.addAll(tplParser.parseErrors.where(rightErrorType));

          if (shorten(directive.source.fullName) !=
              shorten(directive.templateSource.fullName)) {
            errors.addAll(tplErrorListener.errors.where(rightErrorType).map(
                (e) => prefixError(
                    directive.source, directive.classElement.name, e)));
          } else {
            errors.addAll(tplErrorListener.errors.where(rightErrorType));
          }

          fullyResolvedDirectives.add(directive);
        }
      }
    }

    return DirectivesResult(htmlPath, directives, [], errors,
        fullyResolvedDirectives: fullyResolvedDirectives);
  }

  @override
  TopLevel getAngularTopLevel(Element element) {
    final typeSystem = element.context.typeSystem;
    final path = element.source.fullName;
    final summary = _buildUnlinkedAngularTopLevels(path);
    final linker = LazyLinker(typeSystem, standardAngular, standardHtml, this);
    return linkTopLevel(summary, element, linker);
  }

  @override
  List<syntactic.NgContent> getHtmlNgContent(String path) {
    final baseKey = _fileTracker.getContentSignature(path).toHex();
    final key = '$baseKey.ngunlinked';
    final bytes = byteStore.get(key);
    final source = _sourceFor(path);
    if (bytes != null) {
      final linker = EagerLinker(null, null, null, null, null);
      return UnlinkedHtmlSummary.fromBuffer(bytes)
          .ngContents
          .map((ngContent) => linker.ngContent(ngContent, source))
          .toList();
    }

    final htmlContent = fileContent(path);
    final tplErrorListener = RecordingErrorListener();
    final errorReporter = ErrorReporter(tplErrorListener, source);

    final tplParser = TemplateParser()..parse(htmlContent, source);

    final parser = EmbeddedDartParser(source, tplErrorListener, errorReporter);

    final ast = HtmlTreeConverter(parser, source, tplErrorListener)
        .convertFromAstList(tplParser.rawAst);
    final contents = <syntactic.NgContent>[];
    ast.accept(NgContentRecorder(contents, source, errorReporter));

    final summary = UnlinkedHtmlSummaryBuilder()
      ..ngContents = summarizeNgContents(contents);
    final newBytes = summary.toBuffer();
    byteStore.put(key, newBytes);

    return contents;
  }

  @override
  Pipe getPipe(ClassElement element) {
    final typeSystem = element.context.typeSystem;
    final path = element.source.fullName;
    final summary = _buildUnlinkedAngularTopLevels(path);
    final linker = LazyLinker(typeSystem, standardAngular, standardHtml, this);
    return linkPipe(summary.pipeSummaries, element, linker);
  }

  Future<StandardAngular> buildStandardAngular() async {
    if (standardAngular == null) {
      final source =
          _sourceFactory.resolveUri(null, "package:angular/angular.dart");

      if (source == null) {
        return standardAngular;
      }

      final securitySource =
          _sourceFactory.resolveUri(null, SecuritySchema.securitySourcePath);
      final protoSecuritySource = _sourceFactory.resolveUri(
          null, SecuritySchema.protoSecuritySourcePath);

      standardAngular = StandardAngular.fromAnalysis(
          angularResult: await dartDriver.getResult(source.fullName),
          securityResult: await dartDriver.getResult(securitySource.fullName),
          protoSecurityResult: protoSecuritySource == null
              ? null
              : await dartDriver.getResult(protoSecuritySource.fullName));
    }

    return standardAngular;
  }

  Future<StandardHtml> buildStandardHtml() async {
    if (standardHtml == null) {
      final source = _sourceFactory.resolveUri(null, DartSdk.DART_HTML);

      final result = await dartDriver.getResult(source.fullName);
      final securitySchema = (await buildStandardAngular()).securitySchema;

      final components = <String, Component>{};
      final standardEvents = <String, Output>{};
      final customEvents = <String, Output>{};
      final attributes = <String, Input>{};
      result.unit.accept(BuildStandardHtmlComponentsVisitor(
          components, standardEvents, attributes, source, securitySchema));

      for (final event in options.customEvents.values) {
        customEvents[event.name] = await _buildCustomOutputElement(
            event, result.typeProvider.dynamicType);
      }

      standardHtml = StandardHtml(
          components,
          attributes,
          standardEvents,
          customEvents,
          result.libraryElement.exportNamespace.get('Element') as ClassElement,
          result.libraryElement.exportNamespace.get('HtmlElement')
              as ClassElement);
    }

    return standardHtml;
  }

  Future<Output> _buildCustomOutputElement(
      CustomEvent event, DartType dynamicType) async {
    Output defaultOutput() => MissingOutput(
        name: event.name,
        nameRange: SourceRange(event.nameOffset, event.name.length),
        source: options.source,
        eventType: dynamicType);

    final typePath =
        event.typePath ?? (event.typeName != null ? 'dart:core' : null);
    if (typePath == null) {
      return defaultOutput();
    }

    final typeSource = _sourceFactory.resolveUri(null, typePath);
    if (typeSource == null) {
      return defaultOutput();
    }

    final typeResult = await dartDriver.getResult(typeSource.fullName);
    if (typeResult == null) {
      return defaultOutput();
    }

    final typeElement =
        typeResult.libraryElement.publicNamespace.get(event.typeName);
    if (typeElement is ClassElement) {
      var type = typeElement.instantiate(
        typeArguments: typeElement.typeParameters
            .map((p) => p.bound ?? dynamicType)
            .toList(),
        nullabilitySuffix: NullabilitySuffix.star,
      );
      return MissingOutput(
          name: event.name,
          nameRange: SourceRange(event.nameOffset, event.name.length),
          source: options.source,
          eventType: type);
    }
    if (typeElement is TypeDefiningElement) {
      return MissingOutput(
          name: event.name,
          nameRange: SourceRange(event.nameOffset, event.name.length),
          source: options.source,
          eventType: typeElement.type);
    }

    return defaultOutput();
  }

  @override
  ApiSignature getContentHash(String path) {
    final key = ApiSignature();
    final contentBytes = utf8.encode(fileContent(path));
    key.addBytes(md5.convert(contentBytes).bytes);
    return key;
  }

  String fileContent(String path) {
    var overlay = contentOverlay[path];
    if (overlay != null) {
      return overlay;
    }
    Source source = _sourceFor(path);
    return source.exists() ? source.contents.data : '';
  }

  Source _sourceFor(String path) =>
      _resourceProvider.getFile(path).createSource();

  Future<String> _htmlKey(String htmlPath) async {
    final key = await _fileTracker.getHtmlSignature(htmlPath);
    return '${key.toHex()}.ngresolved';
  }

  bool _ownsFile(String path) =>
      path.endsWith('.dart') || path.endsWith('.html');

  AnalysisError _deserializeError(
      Source source, SummarizedAnalysisError error) {
    final errorName = error.errorCode;
    final errorCode = angularWarningCodeByUniqueName(errorName) ??
        errorCodeByUniqueName(errorName);
    if (errorCode == null) {
      return null;
    }
    return AnalysisError.forValues(source, error.offset, error.length,
        errorCode, error.message, error.correction);
  }

  List<AnalysisError> _deserializeErrors(
          Source source, List<SummarizedAnalysisError> errors) =>
      errors
          .map((error) => _deserializeError(source, error))
          .where((e) => e != null)
          .toList();
}

class DirectivesResult {
  final String filename;
  final List<TopLevel> angularTopLevels;
  final List<DirectiveBase> fullyResolvedDirectives = [];
  List<AnalysisError> errors;
  List<Pipe> pipes;
  bool cacheResult;
  DirectivesResult(
      this.filename, this.angularTopLevels, this.pipes, this.errors,
      {List<DirectiveBase> fullyResolvedDirectives = const []})
      : cacheResult = false {
    // Use `addAll` instead of initializing it to `const []` when not specified,
    // so that the result is not const and we can add to it, while still being
    // final.
    this.fullyResolvedDirectives.addAll(fullyResolvedDirectives);
  }

  DirectivesResult.fromCache(this.filename, this.errors)
      : angularTopLevels = const [],
        cacheResult = true;
  List<AnnotatedClass> get angularAnnotatedClasses =>
      List<AnnotatedClass>.from(angularTopLevels.whereType<AnnotatedClass>());

  List<DirectiveBase> get directives =>
      List<DirectiveBase>.from(angularTopLevels.whereType<DirectiveBase>());
}
