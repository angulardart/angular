@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:examples.hacker_news_pwa/app_component.dart';
import 'package:examples.hacker_news_pwa/app_component.template.dart'
    as app_template;
import 'package:examples.hacker_news_pwa/hacker_news_service.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'fake_hacker_news_service.dart';
import 'hacker_news_pwa_test.template.dart' as test_template;
import 'page_objects/app_po.dart';

const service = FakeHackerNewsService();

@GenerateInjector([
  ValueProvider(HackerNewsService, service),
  routerProvidersTest,
])
final InjectorFactory testInjectorFactory =
    test_template.testInjectorFactory$Injector;

void main() {
  AppPO appPO;
  NgTestFixture<AppComponent> testFixture;

  setUp(() async {
    final testBed = NgTestBed.forComponent(app_template.AppComponentNgFactory)
        .addInjector(testInjectorFactory);
    testFixture = await testBed.create();
    final rootElement = testFixture.rootElement;
    final context = HtmlPageLoaderElement.createFromElement(rootElement);
    appPO = AppPO.create(context);
  });

  tearDown(disposeAnyRunningTest);

  test('should render feed items', () async {
    expect(appPO.feedPO.itemPOs, isNotEmpty);
    // The feed name and page are ignored by the fake service.
    final feedData = await service.getFeed(null, null);
    final id = 7; // Test an arbitrary item.
    final itemData = feedData[id];
    final itemPO = appPO.feedPO.itemPOs[id];
    expect(itemPO.title, itemData['title']);
    expect(
      itemPO.subtitle,
      allOf([
        contains(itemData['points'].toString()),
        contains(itemData['user']),
        contains(itemData['time_ago']),
      ]),
    );
  });

  test('should render item discussion when clicked', () async {
    final id = 5; // Test an arbitrary item.
    await testFixture.update((_) {
      appPO.feedPO.itemPOs[id].discussionLink.click();
    });
    expect(appPO.itemDetailPO.commentPOs, isNotEmpty);
    final itemData = await service.getItem('$id');
    final commentData = itemData['comments'].first;
    final commentPO = appPO.itemDetailPO.commentPOs.first;
    expect(commentPO.text, commentData['content']);
  });
}
