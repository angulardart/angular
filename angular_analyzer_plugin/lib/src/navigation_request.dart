import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:angular_analyzer_plugin/src/angular_driver.dart';

class AngularNavigationRequest extends NavigationRequest {
  @override
  final String path;
  @override
  final int length;
  @override
  final int offset;
  final DirectivesResult result;

  AngularNavigationRequest(this.path, this.length, this.offset, this.result);

  @override
  ResourceProvider get resourceProvider => null;
}
