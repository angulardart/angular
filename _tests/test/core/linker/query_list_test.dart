@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/src/core/linker/query_list.dart' show QueryList;

// ignore_for_file: deprecated_member_use

void main() {
  group("QueryList", () {
    QueryList<String> queryList;
    String log;
    setUp(() {
      queryList = new QueryList<String>();
      log = "";
    });
    void logAppend(item) {
      log += (log.length == 0 ? "" : ", ") + item;
    }

    test("should support resetting and iterating over the new objects", () {
      queryList.reset(["one"]);
      queryList.reset(["two"]);
      queryList.forEach(logAppend);
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
      test("should fire callbacks on change", () async {
        var fires = 0;
        queryList.changes.listen((_) {
          fires += 1;
        });
        queryList.notifyOnChanges();
        await new Future.microtask(() => null);
        expect(fires, 1);
        queryList.notifyOnChanges();
        await new Future.microtask(() => null);
        expect(fires, 2);
      });
      test("should provides query list as an argument", () async {
        var recorded;
        queryList.changes.listen((dynamic v) {
          recorded = v;
        });
        queryList.reset(["one"]);
        queryList.notifyOnChanges();
        await new Future.microtask(() => null);
        expect(recorded, queryList);
      });
    });
  });
}
