// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en_US locale. All the
// messages from the main program should be duplicated here with the same
// function name.

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

// ignore: unused_element
final _keepAnalysisHappy = Intl.defaultLocale;

// ignore: non_constant_identifier_names
typedef MessageIfAbsent(String message_str, List args);

class MessageLookup extends MessageLookupByLibrary {
  get localeName => 'en_US';

  static m0(startTag0, endTag0) =>
      "Add items to the grocery list ${startTag0}below$endTag0.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function>{
        "Add": MessageLookupByLibrary.simpleMessage("Add"),
        "Groceries": MessageLookupByLibrary.simpleMessage("Groceries"),
        "Item": MessageLookupByLibrary.simpleMessage("Item"),
        "ViewAppComponent0__message_1": m0
      };
}
