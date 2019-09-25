import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as protocol;
import 'package:angular_analyzer_plugin/plugin.dart';
import 'package:angular_analyzer_plugin/src/angular_driver.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mock_angular.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginIntegrationTest);
    defineReflectiveTests(PluginCreateDriverTest);
    defineReflectiveTests(AnalysisOptionsUtilsTest);
  });
}

/// Convenience functions for assembling `analysis_options.yaml` strings.
///
/// Unfortunately, package:yaml doesn't support dumping to yaml. So this is
/// what we are stuck with, for now. Put it in a base class so we can test it
class AnalysisOptionsUtilsBase extends PluginIntegrationTestBase {
  String optionsHeader = '''
analyzer:
  plugins:
''';

  void enableAnalyzerPluginsAngular({List<String> extraOptions = const []}) =>
      setOptionsFileContent(optionsHeader +
          optionsSection('angular', extraOptions: extraOptions));

  void enableAnalyzerPluginsAngularPlugin(
          {List<String> extraOptions = const []}) =>
      setOptionsFileContent(optionsHeader +
          optionsSection('angular_analyzer_plugin',
              extraOptions: extraOptions));

  String optionsSection(String key, {List<String> extraOptions = const []}) =>
      '''
    $key:${extraOptions.map((option) => "\n      $option").join('')}\n
''';

  void setOptionsFileContent(String content) {
    resourceProvider.newFile('/test/analysis_options.yaml', content);
  }
}

/// Since our yaml generation is...not ideal, let's test it.
@reflectiveTest
class AnalysisOptionsUtilsTest extends AnalysisOptionsUtilsBase {
  // ignore: non_constant_identifier_names
  void test_enableAnalyzerPluginsAngular_extraOptions() {
    enableAnalyzerPluginsAngular(extraOptions: ['foo: bar', 'baz:', '  - qux']);
    final optionsText = resourceProvider
        .getFile('/test/analysis_options.yaml')
        .readAsStringSync();

    expect(optionsText, '''
analyzer:
  plugins:
    angular:
      foo: bar
      baz:
        - qux

''');
  }

  // ignore: non_constant_identifier_names
  void test_enableAnalyzerPluginsAngular_noExtraOptions() {
    enableAnalyzerPluginsAngular();
    final optionsText = resourceProvider
        .getFile('/test/analysis_options.yaml')
        .readAsStringSync();

    expect(optionsText, '''
analyzer:
  plugins:
    angular:

''');
  }

  // ignore: non_constant_identifier_names
  void test_enableAnalyzerPluginsAngularPlugin_extraOptions() {
    enableAnalyzerPluginsAngularPlugin(
        extraOptions: ['foo: bar', 'baz:', '  - qux']);
    final optionsText = resourceProvider
        .getFile('/test/analysis_options.yaml')
        .readAsStringSync();

    expect(optionsText, '''
analyzer:
  plugins:
    angular_analyzer_plugin:
      foo: bar
      baz:
        - qux

''');
  }

  /// Since our yaml generation is...not ideal, let's test it.
  // ignore: non_constant_identifier_names
  void test_enableAnalyzerPluginsAngularPlugin_noExtraOptions() {
    enableAnalyzerPluginsAngularPlugin();
    final optionsText = resourceProvider
        .getFile('/test/analysis_options.yaml')
        .readAsStringSync();

    expect(optionsText, '''
analyzer:
  plugins:
    angular_analyzer_plugin:

''');
  }
}

class MockPluginCommunicationChannel extends Mock
    implements PluginCommunicationChannel {}

class MockResourceProvider extends Mock implements ResourceProvider {}

class NamedNavigationNotificationMatcher implements Matcher {
  final String filename;

  NamedNavigationNotificationMatcher(this.filename);

  @override
  Description describe(Description description) =>
      description..add('that is a navigation notification for file $filename');

  @override
  Description describeMismatch(item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription
        ..add('is not a navigation notification for file $filename');

  @override
  bool matches(item, Map matchState) =>
      item is protocol.Notification &&
      item.event == 'analysis.navigation' &&
      item.params['file'] == filename;
}

@reflectiveTest
class PluginCreateDriverTest extends AnalysisOptionsUtilsBase {
  // ignore: non_constant_identifier_names
  void test_createAnalysisDriver() {
    enableAnalyzerPluginsAngular();
    final driver = plugin.createAnalysisDriver(root) as AngularDriver;

    expect(driver, isNotNull);
    expect(driver.byteStore, isNotNull);
  }

  // ignore: non_constant_identifier_names
  void test_createAnalysisDriver_containsDartDriver() {
    enableAnalyzerPluginsAngular();
    final driver = plugin.createAnalysisDriver(root) as AngularDriver;

    expect(driver, isNotNull);
    expect(driver.dartDriver, isNotNull);
    expect(driver.dartDriver.analysisOptions, isNotNull);
    expect(driver.dartDriver.fsState, isNotNull);
    expect(driver.dartDriver.name, equals("/test"));
    expect(driver.dartDriver.sourceFactory, isNotNull);
    expect(driver.dartDriver.contextRoot, isNotNull);
  }

  // ignore: non_constant_identifier_names
  void test_createAnalysisDriver_customTagNames() {
    enableAnalyzerPluginsAngular(extraOptions: [
      'custom_tag_names:',
      '  - foo',
      '  - bar',
      '  - baz',
    ]);
    final driver = plugin.createAnalysisDriver(root) as AngularDriver;

    expect(driver, isNotNull);
    expect(driver.options, isNotNull);
    expect(driver.options.customTagNames, isNotNull);
    expect(driver.options.customTagNames, equals(['foo', 'bar', 'baz']));
  }

  // ignore: non_constant_identifier_names
  void test_createAnalysisDriver_customTagNames_pluginSelfLoader() {
    enableAnalyzerPluginsAngularPlugin(extraOptions: [
      'custom_tag_names:',
      '  - foo',
      '  - bar',
      '  - baz',
    ]);
    final driver = plugin.createAnalysisDriver(root) as AngularDriver;

    expect(driver, isNotNull);
    expect(driver.options, isNotNull);
    expect(driver.options.customTagNames, isNotNull);
    expect(driver.options.customTagNames, equals(['foo', 'bar', 'baz']));
  }

  // ignore: non_constant_identifier_names
  void test_createAnalysisDriver_defaultOptions() {
    enableAnalyzerPluginsAngular();
    final driver = plugin.createAnalysisDriver(root) as AngularDriver;

    expect(driver, isNotNull);
    expect(driver.options, isNotNull);
    expect(driver.options.customTagNames, isNotNull);
    expect(driver.options.customTagNames, isEmpty);
  }
}

@reflectiveTest
class PluginIntegrationTest extends PluginIntegrationTestBase {
  @override
  void setUp() async {
    super.setUp();

    addAngularSources((filename, [contents = ""]) =>
        resourceProvider.newFile(filename, contents));
    resourceProvider.newFile('/test/.packages', 'angular:/angular/');
    plugin.start(mockChannel);
    await plugin.handleAnalysisSetContextRoots(
        protocol.AnalysisSetContextRootsParams([root]));
  }

  // ignore: non_constant_identifier_names
  void test_navigation_dart() async {
    resourceProvider.newFile('/test/test.dart', r'''
import 'package:angular/angular.dart';
@Component(
  selector: 'foo'
)
class MyComponent {}
''');

    await (plugin.driverForPath('/test/test.dart') as AngularDriver)
        .requestDartResult('/test/test.dart');
    verifyNever(mockChannel.sendNotification(
        argThat(NamedNavigationNotificationMatcher('/test/test.dart'))));

    await plugin.handleAnalysisSetSubscriptions(
        protocol.AnalysisSetSubscriptionsParams({
      protocol.AnalysisService.NAVIGATION: ['/test/test.dart']
    }));

    await Future.delayed(const Duration(milliseconds: 300));
    verify(mockChannel.sendNotification(
        argThat(NamedNavigationNotificationMatcher('/test/test.dart'))));
  }

  // ignore: non_constant_identifier_names
  void test_navigation_html() async {
    resourceProvider..newFile('/test/test.dart', r'''
import 'package:angular/angular.dart';
@Component(
  selector: 'foo'
  templateUrl: 'test.html';
)
class MyComponent {}
''')..newFile('/test/test.html', '');

    final driver = plugin.driverForPath('/test/test.dart') as AngularDriver;
    await driver.requestDartResult('/test/test.dart');
    await driver.requestHtmlResult('/test/test.html');
    verifyNever(mockChannel.sendNotification(
        argThat(NamedNavigationNotificationMatcher('/test/test.html'))));

    await plugin.handleAnalysisSetSubscriptions(
        protocol.AnalysisSetSubscriptionsParams({
      protocol.AnalysisService.NAVIGATION: ['/test/test.html']
    }));

    await Future.delayed(const Duration(milliseconds: 300));
    verify(mockChannel.sendNotification(
        argThat(NamedNavigationNotificationMatcher('/test/test.html'))));
  }
}

class PluginIntegrationTestBase {
  AngularAnalyzerPlugin plugin;
  MemoryResourceProvider resourceProvider;
  PluginCommunicationChannel mockChannel;
  protocol.ContextRoot root;
  void setUp() {
    resourceProvider = MemoryResourceProvider();
    MockSdk(resourceProvider: resourceProvider);
    plugin = AngularAnalyzerPlugin(resourceProvider);
    final versionCheckParams = protocol.PluginVersionCheckParams(
        "~/.dartServer/.analysis-driver", "/sdk", "1.0.0");
    plugin.handlePluginVersionCheck(versionCheckParams);
    root = protocol.ContextRoot("/test", [],
        optionsFile: '/test/analysis_options.yaml');
    mockChannel = MockPluginCommunicationChannel();
  }
}
