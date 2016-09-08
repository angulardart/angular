import 'package:angular2/src/transform/common/options_reader.dart';
import 'package:barback/barback.dart';

void main() {
  var settings = new BarbackSettings({
    'entry_points': [
      'non_existing1',
      'non_existing2/with_sub_directory',
      './test/transform/common/print_invalid_entry_points.dart'
    ]
  }, BarbackMode.DEBUG);
  parseBarbackSettings(settings);
}
