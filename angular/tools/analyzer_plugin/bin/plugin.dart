import 'dart:isolate';

// ignore: uri_does_not_exist
import 'package:angular_analyzer_plugin/starter.dart' as plugin;

void main(List<String> args, SendPort sendPort) {
  plugin.start(args, sendPort);
}
