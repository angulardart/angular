import 'dart:async';

import 'package:analyzer/context/context_root.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/plugin/completion_mixin.dart';
import 'package:analyzer_plugin/plugin/navigation_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:angular_analyzer_plugin/src/angular_driver.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_completion_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_inherited_reference_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_type_member_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/angular_offset_length_contributor.dart';
import 'package:angular_analyzer_plugin/src/completion/request.dart';
import 'package:angular_analyzer_plugin/src/navigation.dart';
import 'package:angular_analyzer_plugin/src/navigation_request.dart';
import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:meta/meta.dart';

class AngularAnalyzerPlugin extends ServerPlugin
    with CompletionMixin, NavigationMixin {
  AngularAnalyzerPlugin(ResourceProvider provider) : super(provider);

  @override
  String get contactInfo =>
      'Please file issues at https://github.com/dart-lang/angular/issues';

  @override
  List<String> get fileGlobsToAnalyze => <String>['*.dart', '*.html'];

  @override
  String get name => 'Angular Analysis Plugin';

  @override
  String get version => '1.0.0-alpha.0';

  AngularDriver angularDriverForPath(String path) {
    final driver = super.driverForPath(path);
    if (driver is AngularDriver) {
      return driver;
    }
    return null;
  }

  @override
  void contentChanged(String path) {
    final driver = angularDriverForPath(path);
    if (driver == null) {
      return;
    }

    driver
      ..addFile(path) // TODO new API to only do this on file add
      ..fileChanged(path);

    driver.dartDriver
      ..addFile(path) // TODO new API to only do this on file add
      ..changeFile(path);
  }

  @override
  AnalysisDriverGeneric createAnalysisDriver(plugin.ContextRoot contextRoot) {
    final root = ContextRoot(contextRoot.root, contextRoot.exclude,
        pathContext: resourceProvider.pathContext)
      ..optionsFilePath = contextRoot.optionsFile;
    final options = getOptions(root.optionsFilePath);

    final logger = PerformanceLog(StringBuffer());
    final builder = ContextBuilder(resourceProvider, sdkManager, null)
      ..analysisDriverScheduler = (AnalysisDriverScheduler(logger)..start())
      ..byteStore = byteStore
      ..performanceLog = logger
      ..fileContentOverlay = fileContentOverlay;

    final dartDriver = builder.buildDriver(root)
      ..results.listen((_) {}) // Consume the stream, otherwise we leak.
      ..exceptions.listen((_) {}); // Consume the stream, otherwise we leak.

    final sourceFactory = dartDriver.sourceFactory;

    final driver = AngularDriver(
        resourceProvider,
        dartDriver,
        analysisDriverScheduler,
        byteStore,
        sourceFactory,
        fileContentOverlay,
        options);

    driver.dartResultsStream
        .listen((result) => onResult(result, driver, isHtml: false));
    driver.htmlResultsStream
        .listen((result) => onResult(result, driver, isHtml: true));
    return driver;
  }

  @override
  List<CompletionContributor> getCompletionContributors(String path) {
    if (angularDriverForPath(path) == null) {
      return [];
    }

    return <CompletionContributor>[
      AngularCompletionContributor(),
      AngularInheritedReferenceContributor(),
      AngularTypeMemberContributor(),
      AngularOffsetLengthContributor(),
    ];
  }

  @override
  Future<CompletionRequest> getCompletionRequest(
      plugin.CompletionGetSuggestionsParams parameters) async {
    final path = parameters.file;
    final driver = angularDriverForPath(path);
    final offset = parameters.offset;

    if (driver == null) {
      return DartCompletionRequestImpl(resourceProvider, offset, null);
    }

    final templates = await driver.computeTemplatesForFile(path);
    final standardHtml = await driver.buildStandardHtml();
    assert(standardHtml != null);
    return AngularCompletionRequest(
        offset, path, resourceProvider, templates, standardHtml);
  }

  /// Return the navigation contributors for click-through support.
  @override
  List<NavigationContributor> getNavigationContributors(String path) =>
      [AngularNavigation(angularDriverForPath(path).contentOverlay)];

  /// Build a navigation request to be passed to the result of
  /// [getNavigationContributors].
  @override
  Future<NavigationRequest> getNavigationRequest(
      plugin.AnalysisGetNavigationParams parameters) async {
    final driver = driverForPath(parameters.file) as AngularDriver;
    final isHtml = parameters.file.endsWith('.html');
    final result = isHtml
        ? await driver.requestHtmlResult(parameters.file)
        : await driver.requestDartResult(parameters.file);
    return AngularNavigationRequest(
        parameters.file, parameters.offset, parameters.length, result);
  }

  AngularOptions getOptions(String optionsFilePath) {
    if (optionsFilePath != null && optionsFilePath.isNotEmpty) {
      final file = resourceProvider.getFile(optionsFilePath);
      if (file.exists) {
        return AngularOptions.from(file.createSource());
      }
    }
    return AngularOptions.defaults();
  }

  /// Handle any errors that may occur in the analysis server.
  ///
  /// This method will not be invoked under normal conditions.
  @override
  void onError(Object exception, StackTrace stackTrace) {
    print('Communication Exception: $exception\n$stackTrace');
    // ignore: only_throw_errors
    throw exception;
  }

  void onResult(DirectivesResult result, AngularDriver driver,
      {@required bool isHtml}) {
    _handleResultErrors(result, driver);
    _handleResultNavigation(result, driver, isHtml: isHtml);
  }

  /// This method is used when the set of subscribed notifications has been
  /// changed and notifications need to be sent even when the specified files
  /// have already been analyzed.
  @override
  void sendNotificationsForSubscriptions(
      Map<String, List<plugin.AnalysisService>> subscriptions) {
    subscriptions.forEach((filePath, services) {
      final driver = angularDriverForPath(filePath);
      if (driver == null) {
        return;
      }

      // Kick off a full reanalysis of files with subscriptions. This will add
      // a resolved result to the stream which will send the new necessary
      // notifications.
      filePath.endsWith('.dart')
          ? driver.requestDartResult(filePath)
          : driver.requestHtmlResult(filePath);
    });
  }

  /// Send notifications for errors for this result.
  void _handleResultErrors(DirectivesResult result, AngularDriver driver) {
    final converter = AnalyzerConverter();
    final lineInfo = LineInfo.fromContent(driver.fileContent(result.filename));
    // TODO(mfairhurst) Get the right analysis options.
    final errors = converter.convertAnalysisErrors(
      result.errors,
      lineInfo: lineInfo,
    );
    channel.sendNotification(
        plugin.AnalysisErrorsParams(result.filename, errors).toNotification());
  }

  /// Send notifications for navigation for this result.
  void _handleResultNavigation(DirectivesResult result, AngularDriver driver,
      {@required bool isHtml}) {
    final collector = NavigationCollectorImpl();
    final filename = result.filename;
    if (filename == null ||
        !subscriptionManager.hasSubscriptionForFile(
            filename, plugin.AnalysisService.NAVIGATION)) {
      return;
    }

    if (result.cacheResult) {
      // get a non-cached result, so we have an AST.
      // TODO(mfairhurst) make this assurance in a less hacky way
      isHtml
          ? driver.requestHtmlResult(filename)
          : driver.requestDartResult(filename);
      return;
    }

    AngularNavigation(driver.contentOverlay).computeNavigation(
        AngularNavigationRequest(filename, null, null, result), collector,
        templatesOnly: isHtml);
    collector.createRegions();
    channel.sendNotification(plugin.AnalysisNavigationParams(
            filename, collector.regions, collector.targets, collector.files)
        .toNotification());
  }
}
