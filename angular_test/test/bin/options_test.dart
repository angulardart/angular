// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular_test/src/bin/options.dart';
import 'package:angular_test/src/bin/logging.dart';

void main() {
  final logs = <String>[];
  initLoggingForTest('options_test', logs);

  // Clear the log buffer after every test case.
  tearDown(logs.clear);

  test('CliOptions should have a reasonable default', () {
    final options = new CliOptions.fromArgs([]);
    expect(
      options.testArgs,
      ['run', 'test'],
    );
    expect(
      options.serveArgs,
      [
        'serve',
        'test',
        '--port=0',
      ],
    );
  });

  test('CliOptions should parse --port [DEPRECATED]', () {
    final options = new CliOptions.fromArgs(['--port=1234']);
    expect(
      options.serveArgs,
      [
        'serve',
        'test',
        '--port=1234',
      ],
    );
    expect(logs.join('\n'), contains('"port" is deprecated'));
  });

  test('CliOptions should parse --verbose', () {
    final options = new CliOptions.fromArgs(['--verbose']);
    expect(options.verbose, isTrue);
  });

  test('CliOptions should parse --pub-path', () {
    final options = new CliOptions.fromArgs(['--pub-path=/some/local/pub']);
    expect(options.pubBin, '/some/local/pub');
  });

  test('CliOptions should parse --package', () {
    final options = new CliOptions.fromArgs(['--package=/some/package']);
    expect(options.package, '/some/package');
  });

  test('CliOptions should parse --serve-arg', () {
    final options = new CliOptions.fromArgs(['--serve-arg=--port=1234']);
    expect(
      options.serveArgs,
      [
        'serve',
        'test',
        '--port=1234',
      ],
    );
  });

  test('CliOptions should parse multiple --serve-arg(s)', () {
    final options = new CliOptions.fromArgs([
      '--serve-arg=--port=1234',
      '--serve-arg=--mode=release',
    ]);
    expect(
      options.serveArgs,
      [
        'serve',
        'test',
        '--port=1234',
        '--mode=release',
      ],
    );
  });

  test('CliOptions should parse --run-test-flag', () {
    final options = new CliOptions.fromArgs(['--run-test-flag=angular']);
    expect(
      options.testArgs,
      ['run', 'test', '--tags=angular'],
    );
    expect(logs.join('\n'), contains('"run-test-flag" is deprecated'));
  });

  test('CliOptions should parse --platform', () {
    final options = new CliOptions.fromArgs(['--platform=chrome']);
    expect(
      options.testArgs,
      ['run', 'test', '--platform=chrome'],
    );
    expect(logs.join('\n'), contains('"platform" is deprecated'));
  });

  test('CliOptions should parse --name', () {
    final options = new CliOptions.fromArgs(['--name=ngIf']);
    expect(
      options.testArgs,
      ['run', 'test', '--name=ngIf'],
    );
    expect(logs.join('\n'), contains('"name" is deprecated'));
  });

  test('CliOptions should parse --plain-name', () {
    final options = new CliOptions.fromArgs(['--plain-name=ngIf']);
    expect(
      options.testArgs,
      ['run', 'test', '--plain-name=ngIf'],
    );
    expect(logs.join('\n'), contains('"plain-name" is deprecated'));
  });

  test('CliOptions should parse --test-arg(s)', () {
    final options = new CliOptions.fromArgs([
      '--test-arg=--platform=chrome',
      '--test-arg=--tags=angular',
      '--test-arg=--name=ngIf',
    ]);
    expect(
      options.testArgs,
      ['run', 'test', '--platform=chrome', '--tags=angular', '--name=ngIf'],
    );
  });
}
