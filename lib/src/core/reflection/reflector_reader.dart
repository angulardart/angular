/**
 * Provides read-only access to reflection data about symbols. Used internally by Angular
 * to power dependency injection and compilation.
 */

abstract class ReflectorReader {
  List<List<dynamic>> parameters(dynamic typeOrFunc);
  List<dynamic> annotations(dynamic typeOrFunc);
  Map<String, List<dynamic>> propMetadata(dynamic typeOrFunc);
}
