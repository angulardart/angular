import 'package:build/build.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  tearDown(CompileContext.removeTestingOverride);

  group('CompileContext.current', () {
    test('should throw if not configured', () {
      expect(() => CompileContext.current, throwsStateError);
    });

    test('should normally use runWithContext', () {
      final context = CompileContext.forTesting();
      runWithContext(context, expectAsync0(() async {
        expect(CompileContext.current, same(context));
      }));
    });

    test('takes precedence from overrideWithTesting', () {
      final contextA = CompileContext.forTesting();
      final contextB = CompileContext.forTesting();
      CompileContext.overrideForTesting(contextB);
      runWithContext(contextA, expectAsync0(() async {
        expect(CompileContext.current, same(contextB));
      }));
    });
  });

  group('CompileContext', () {
    test('path should be a full file path/url', () {
      final context = CompileContext(
        AssetId('foo.sub', 'lib/bar.dart'),
        enableDevTools: false,
        isNullSafe: false,
        policyExceptions: {},
        policyExceptionsInPackages: {},
      );
      expect(context.path, 'foo/sub/lib/bar.dart');
    });

    test('path should understand third_party/dart convention', () {
      final context = CompileContext(
        AssetId('foo', 'lib/bar.dart'),
        enableDevTools: false,
        isNullSafe: false,
        policyExceptions: {},
        policyExceptionsInPackages: {},
      );
      expect(context.path, 'third_party/dart/foo/lib/bar.dart');
    });

    test('reportAndRecover should collect errors for later', () {
      final context = CompileContext(
        AssetId('foo.sub', 'lib/bar.dart'),
        enableDevTools: false,
        isNullSafe: false,
        policyExceptions: {},
        policyExceptionsInPackages: {},
      );
      final badButRecoverable = BuildError.withoutContext('Oops');
      expect(
        () => context.reportAndRecover(badButRecoverable),
        returnsNormally,
      );
      expect(
        () => context.throwRecoverableErrors(),
        throwsA(predicate((e) => '$e'.contains('$badButRecoverable'))),
      );
      expect(
        () => context.throwRecoverableErrors(),
        returnsNormally,
      );
    });

    group('emitNullSafeCode', () {
      test('should be false if the source library is not opted-in', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: false,
          policyExceptions: {},
          policyExceptionsInPackages: {},
        );
        expect(context.emitNullSafeCode, isFalse);
      });

      test('should be true if the source library opted-in', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: true,
          policyExceptions: {},
          policyExceptionsInPackages: {},
        );
        expect(context.emitNullSafeCode, isTrue);
      });
    });

    group('isDevToolsEnabled', () {
      test('should be false by default', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: false,
          policyExceptions: {},
          policyExceptionsInPackages: {},
        );
        expect(context.isDevToolsEnabled, isFalse);
      });

      test('should be true if enabled globally', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: true,
          isNullSafe: false,
          policyExceptions: {},
          policyExceptionsInPackages: {},
        );
        expect(context.isDevToolsEnabled, isTrue);
      });

      test('should be true if specifically allow-listed', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: false,
          policyExceptions: {
            'FORCE_DEVTOOLS_ENABLED': {
              'foo/sub/lib/bar.dart',
            },
          },
          policyExceptionsInPackages: {},
        );
        expect(context.isDevToolsEnabled, isTrue);
      });
    });

    group('validateMissingDirectives', () {
      test('should be true by default', () {
        final context = CompileContext(
          AssetId('foo', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: false,
          policyExceptions: {},
          policyExceptionsInPackages: {},
        );
        expect(context.validateMissingDirectives, isTrue);
      });

      test('should be false if in an disallow-listed directory/tree', () {
        final context = CompileContext(
          AssetId('foo.sub', 'lib/bar.dart'),
          enableDevTools: false,
          isNullSafe: false,
          policyExceptions: {},
          policyExceptionsInPackages: {
            'EXCLUDED_VALIDATE_MISSING_DIRECTIVES': {
              'foo/sub',
            },
          },
        );
        expect(context.validateMissingDirectives, isFalse);
      });
    });
  });

  group('CompileContext.forTesting', () {
    test('should immediately throw errors', () {
      final context = CompileContext.forTesting();
      final badButRecoverable = BuildError.withoutContext('Oops');
      expect(
        () => context.reportAndRecover(badButRecoverable),
        // We want to assert that specifically the message is the same; it does
        // not need to be the exact same instance.
        throwsA(predicate((e) => '$e' == '$badButRecoverable')),
      );
    });
  });

  group('runWithContext', () {
    test('should complete normally', () async {
      final result = await runWithContext(
        CompileContext.forTesting(),
        () async => 'Done',
      );
      expect(result, 'Done');
    });
  });
}
