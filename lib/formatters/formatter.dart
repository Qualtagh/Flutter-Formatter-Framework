import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/cancel_exception.dart';
import 'package:flutter_formatter_framework/types/change.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';

abstract class Formatter extends TextInputFormatter {
  /// Set to true to print test cases for Formatter tests
  static bool isDebug = false;

  /// Apply formatting to the text
  String format(String text) {
    return formatEditUpdate(const TextEditingValue(text: ''), TextEditingValue(text: text)).text;
  }

  /// Strip applied formatting from the text
  String deformat(String text);

  /// Call this function to print a test case for Formatter tests
  void printTestCase(TextEditingValue oldValue, TextEditingValue newValue, [String? text, int? position]) {
    if (!isDebug) {
      return;
    }
    if (text == null || position == null) {
      print(
        "t('${oldValue.text}', ${oldValue.selection.start}, ${oldValue.selection.end}, '${newValue.text}', ${newValue.selection.end});",
      );
      return;
    }
    print(
      "t('${oldValue.text}', ${oldValue.selection.start}, ${oldValue.selection.end}, '${newValue.text}', ${newValue.selection.end}, '$text', $position);",
    );
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final change = getChange(oldValue, newValue);
    final context = TextEditingContext(old: oldValue, edited: newValue, preformatted: newValue, change: change);
    try {
      final formatted = formatUpdate(context);
      printTestCase(oldValue, newValue, formatted.text, formatted.selection.end);
      return formatted;
    } catch (e) {
      if (e is! CancelException) {
        rethrow;
      }
      printTestCase(oldValue, newValue);
      return oldValue;
    }
  }

  TextEditingValue formatUpdate(TextEditingContext context);
}
