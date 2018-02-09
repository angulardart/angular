import 'package:angular/angular.dart';

@Component(
  selector: 'has-template-file',
  templateUrl: 'has_template_file.html',
  styleUrls: const ['has_template_file.css'],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HasTemplateFileComponent {}
