library angular2.src.platform.worker_render;

import 'dart:async';
import 'dart:isolate';

import 'package:angular2/core.dart';
import 'package:angular2/src/core/di.dart';
import 'package:angular2/src/platform/worker_render_common.dart'
    show WORKER_RENDER_APPLICATION_COMMON, initializeGenericWorkerRenderer;
import 'package:angular2/src/web_workers/shared/isolate_message_bus.dart';
import 'package:angular2/src/web_workers/shared/message_bus.dart';

const WORKER_RENDER_APP = WORKER_RENDER_APPLICATION_COMMON;

Future<List> initIsolate(String scriptUri) async {
  var instance = await spawnIsolate(Uri.parse(scriptUri));

  return [
    WORKER_RENDER_APPLICATION_COMMON,
    new Provider(WebWorkerInstance, useValue: instance),
    new Provider(APP_INITIALIZER,
        useFactory: (injector) =>
            () => initializeGenericWorkerRenderer(injector),
        multi: true,
        deps: [Injector]),
    new Provider(MessageBus, useValue: instance.bus)
  ];
}

/**
 * Spawns a new class and initializes the WebWorkerInstance
 */
Future<WebWorkerInstance> spawnIsolate(Uri uri) async {
  var receivePort = new ReceivePort();
  var isolateEndSendPort = receivePort.sendPort;
  var isolate = await Isolate.spawnUri(uri, const [], isolateEndSendPort);
  var source = new UIMessageBusSource(receivePort);
  var sendPort = await source.sink;
  var sink = new IsolateMessageBusSink(sendPort);
  var bus = new IsolateMessageBus(sink, source);

  return new WebWorkerInstance(isolate, bus);
}

class UIMessageBusSource extends IsolateMessageBusSource {
  UIMessageBusSource(ReceivePort port) : super(port);

  Future<SendPort> get sink => stream.firstWhere((message) {
        return message is SendPort;
      }) as Future<SendPort>;
}

/**
 * Wrapper class that exposes the Isolate
 * and underlying {@link MessageBus} for lower level message passing.
 */
class WebWorkerInstance {
  Isolate worker;
  MessageBus bus;

  WebWorkerInstance(this.worker, this.bus);
}
