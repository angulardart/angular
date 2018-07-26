import 'dart:async';
import 'dart:html' show Event;

import 'package:angular/angular.dart';

import '../model.dart';
import 'control_container.dart';
import 'form_interface.dart';
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;

/// A base implementation of [Form].
abstract class AbstractForm<T extends AbstractControlGroup>
    extends ControlContainer<T> implements Form {
  final _ngSubmit = StreamController<T>.broadcast(sync: true);
  final _ngBeforeSubmit = StreamController<T>.broadcast(sync: true);

  T get form;

  /// An event fired with the user has triggered a form submission.
  @Output()
  Stream<T> get ngSubmit => _ngSubmit.stream;

  /// An event that is fired before the main form submission event.
  ///
  /// This is intended to be used to set form values or perform validation on
  /// submit instead of when a value changes.
  @Output()
  Stream<T> get ngBeforeSubmit => _ngBeforeSubmit.stream;

  @HostListener('submit')
  void onSubmit(Event event) {
    _ngBeforeSubmit.add(form);
    _ngSubmit.add(form);
    event?.preventDefault();
  }

  @HostListener('reset')
  void onReset(Event event) {
    reset();
    event?.preventDefault();
  }

  @override
  Form get formDirective => this;

  @override
  T get control => form;

  @override
  List<String> get path => [];

  @override
  Control getControl(NgControl dir) => form?.findPath(dir.path) as Control;

  @override
  AbstractControlGroup getControlGroup(NgControlGroup dir) =>
      form?.findPath(dir.path) as AbstractControlGroup;

  @override
  void updateModel(NgControl dir, dynamic value) {
    var ctrl = getControl(dir);
    ctrl?.updateValue(value);
  }
}
