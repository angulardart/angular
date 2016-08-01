/**
 * @license
 * Copyright Google Inc. All Rights Reserved.
 *
 * Use of this source code is governed by an MIT-style license that can be
 * found in the LICENSE file at https://angular.io/license
 */

import 'package:angular2/core.dart';

import 'async_pipe.dart';

@Component(
    selector: 'my-app',
    templateUrl: 'app_component.html',
    directives: const [AsyncGreeterPipe, AsyncTimePipe])
class AppComponent {}
