import 'dart:io';

import 'package:args/args.dart';
import 'package:angular_info/angular_info_generator.dart';

main(List<String> mainArgs) async {
  var parser = ArgParser();
  parser.addOption('output',
      help: 'Path where the output file will be written');

  var parsedArgs = parser.parse(mainArgs);

  String textReportContent = await AngularInfoGenerator(
          parsedArgs.rest.map((path) => File(path).readAsString()))
      .generateTextReport();

  await File(parsedArgs['output']).writeAsString(textReportContent + '\n');
}
