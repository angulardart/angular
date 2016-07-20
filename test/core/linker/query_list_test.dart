@TestOn('browser')
library angular2.test.core.linker.query_list_spec;

import "package:angular2/src/core/linker/query_list.dart" show QueryList;
import "package:angular2/src/facade/async.dart" show ObservableWrapper;
import "package:angular2/src/facade/collection.dart" show iterateListLike;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("QueryList", () {
    QueryList<String> queryList;
    String log;
    setUp(() {
      queryList = new QueryList<String>();
      log = "";
    });
    logAppend(item) {
      log += (log.length == 0 ? "" : ", ") + item;
    }
    test("should support resetting and iterating over the new objects", () {
      queryList.reset(["one"]);
      queryList.reset(["two"]);
      iterateListLike(queryList, logAppend);
      expect(log, "two");
    });
    test("should support length", () {
      queryList.reset(["one", "two"]);
      expect(queryList.length, 2);
    });
    test("should support map", () {
      queryList.reset(["one", "two"]);
      expect(queryList.map((x) => x), ["one", "two"]);
    });
    test("should support forEach", () {
      queryList.reset(["one", "two"]);
      var join = "";
      queryList.forEach((x) => join = join + x);
      expect(join, "onetwo");
    });
    test("should support toString", () {
      queryList.reset(["one", "two"]);
      var listString = queryList.toString();
      expect(listString, contains("one"));
      expect(listString, contains("two"));
    });
    test("should support first and last", () {
      queryList.reset(["one", "two", "three"]);
      expect(queryList.first, "one");
      expect(queryList.last, "three");
    });
    group("simple observable interface", () {
      test("should fire callbacks on change", fakeAsync(() {
        var fires = 0;
        ObservableWrapper.subscribe(queryList.changes, (_) {
          fires += 1;
        });
        queryList.notifyOnChanges();
        tick();
        expect(fires, 1);
        queryList.notifyOnChanges();
        tick();
        expect(fires, 2);
      }));
      test("should provides query list as an argument", fakeAsync(() {
        var recorded;
        ObservableWrapper.subscribe(queryList.changes, (dynamic v) {
          recorded = v;
        });
        queryList.reset(["one"]);
        queryList.notifyOnChanges();
        tick();
        expect(recorded, queryList);
      }));
    });
  });
}
