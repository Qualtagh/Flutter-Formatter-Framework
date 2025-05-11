import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/simple_formatter.dart';
import 'package:flutter_formatter_framework/types/cancel_exception.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';
import 'package:flutter_formatter_framework/util/detect_text_change.dart';

/// Base class for all formatters of this framework
abstract class Formatter extends TextInputFormatter {
  /// Set to true to print test cases for Formatter tests
  static bool isDebug = false;

  const Formatter();

  const factory Formatter.withFunction(FormatUpdateFunction formatUpdate, [DeformatFunction? deformat]) =
      SimpleFormatter;

  /// Apply formatting to the text
  String format(String text) => formatEditUpdate(const TextEditingValue(text: ''), TextEditingValue(text: text)).text;

  /// Strip applied formatting from the text
  String deformat(String text);

  /// Call this function to print a test case for Formatter tests
  void printTestCase(TextEditingValue oldValue, TextEditingValue newValue, [String? text, int? position]) {
    if (!isDebug) {
      return;
    }
    final testCase =
        text == null || position == null
            ? "t('${oldValue.text}', ${oldValue.selection.start}, ${oldValue.selection.end}, '${newValue.text}', ${newValue.selection.end});"
            : "t('${oldValue.text}', ${oldValue.selection.start}, ${oldValue.selection.end}, '${newValue.text}', ${newValue.selection.end}, '$text', $position);";
    print(testCase);
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final change = detectTextChange(oldValue, newValue);
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
