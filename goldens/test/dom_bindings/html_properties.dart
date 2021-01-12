@JS()
library golden;

import 'package:js/js.dart';
import 'package:safe_html/safe_html.dart';
import 'package:angular/angular.dart';

import 'html_properties.template.dart' as ng;

/// Avoids Dart2JS thinking something is constant/unchanging.
@JS()
external T deopt<T>([Object? any]);

void main() {
  runApp(ng.createGoldenComponentFactory());
}

@Component(
  selector: 'golden',
  directives: [
    SanitizedComponent,
  ],
  template: '''
    <!-- Statically add a class -->
    <div class="static"></div>
    <div [class]="'static'"></div>
    <div [class.static]="true"></div>

    <!-- Dynamically add a class -->
    <div [class]="string"></div>
    <div [class.dynamic]="boolean"></div>

    <!-- Statically add attributes -->
    <div role="progressbar"></div>
    <div [attr.role]="'progressbar'"></div>
    <div [attr.disabled.if]="true"></div>

    <!-- Dynamically add attributes -->
    <div [attr.role]="string"></div>
    <div [attr.disabled.if]="boolean"></div>

    <sanitized></sanitized>
  ''',
)
class GoldenComponent {
  String string = deopt();
  bool boolean = deopt();
}

@Component(
  selector: 'sanitized',
  template: '''
    <!-- Statically add a href -->
    <a href="https://google.com"></a>

    <!-- Dynamically add a href -->
    <a [href]="googleDotCom"></a>
    <a [href]="maybeUnsafe"></a>

    <!-- Statically add a src -->
    <iframe src="https://google.com"></iframe>

    <!-- Dynamically add a src -->
    <iframe [src]="youtubeUrl"></iframe>

    <!-- Dynamically add innerHtml -->
    <div [innerHtml]="safeHtml"></div>
    <div [innerHtml]="maybeUnsafe"></div>
  ''',
)
class SanitizedComponent {
  final googleDotCom = SafeUrl.fromConstant('https://google.com');
  final safeHtml = SafeHtml.sanitize('<div></div>');
  String maybeUnsafe = deopt();
  final youtubeUrl = TrustedResourceUrl.sanitizeFormatted(
    '//www.youtube.com/v/%{videoId}?h1=en&fs=1',
    {
      'videoId': '5',
    },
  );
}
