import 'package:meta/meta.dart';
import 'messages/messages.dart';

/// Returns the currently bound [Messages] instance.
final Messages messages = const $Messages();

/// Defines common messages to use during compilation.
abstract class Messages {
  @visibleForOverriding
  const Messages.base();

  /// Possible reasons that static analysis/the compiler failed.
  String get analysisFailureReasons;

  /// What URL should be used for filing bugs when the compiler fails.
  String get urlFileBugs;
}
