import 'dart:async';
import 'dart:html' show Event;

import 'package:angular/angular.dart';

import '../model.dart';
import 'control_container.dart';
import 'form_interface.dart';
import 'ng_control.dart' show NgControl;
import 'ng_control_group.dart' show NgControlGroup;

/// A base implementation of [Form].
abstract class AbstractForm extends ControlContainer implements Form {
  final _ngSubmit = new StreamController<ControlGroup>.broadcast(sync: true);
  final _ngBeforeSubmit =
      new StreamController<ControlGroup>.broadcast(sync: true);

  ControlGroup get form;

  /// An event fired with the user has triggered a form submission.
  @Output()
  Stream<ControlGroup> get ngSubmit => _ngSubmit.stream;

  /// An event that is fired before the main form submission event.
  ///
  /// This is intended to be used to set form values or perform validation on
  /// submit instead of when a value changes.
  @Output()
  Stream<ControlGroup> get ngBeforeSubmit => _ngBeforeSubmit.stream;

  @HostListener('submit')
  void onSubmit(Event event) {
    _ngBeforeSubmit.add(form);
    _ngSubmit.add(form);
    event?.preventDefault();
  }

  @override
  Form get formDirective => this;

  @override
  ControlGroup get control => form;

  @override
  List<String> get path => [];

  @override
  Control getControl(NgControl dir) => form?.findPath(dir.path) as Control;

  @override
  ControlGroup getControlGroup(NgControlGroup dir) =>
      (form?.findPath(dir.path) as ControlGroup);

  @override
  void updateModel(NgControl dir, dynamic value) {
    var ctrl = getControl(dir);
    ctrl?.updateValue(value);
  }
}
