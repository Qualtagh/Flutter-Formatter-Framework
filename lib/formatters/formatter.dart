import 'dart:core';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/change_type.dart';
import 'package:flutter_formatter_framework/formatters/text_editing_context.dart';
import 'package:flutter_formatter_framework/util/string_extension.dart';

class CancelException implements Exception {}

class ProcessingResult {
  /// A sequence to insert instead of the original character.
  /// Examples:
  /// - full input - '$', input char - '$', output sequence - '$0', full output - '$0'
  /// - full input - '2358', input char - '5', output sequence - '-5', full output - '23-58'
  final String sequence;

  /// A shift of the cursor position. By default, it's a length of the sequence.
  /// Example: full input - '10.', input char - '.', output sequence - '.00', full output - '10.00'
  /// - cursor shift - 3 (default), position - '10.00|'
  /// - cursor shift - 2, position - '10.0|0'
  /// - cursor shift - 1, position - '10.|00'
  /// - cursor shift - 0, position - '10|.00'
  /// Note that it's only applied in case of insertion. Deletion of characters ignores this value.
  final int cursorShift;

  ProcessingResult({required this.sequence, int? cursorShift}) : cursorShift = cursorShift ?? sequence.length;
}

abstract class Formatter extends TextInputFormatter {
  /// Set to true to print test cases for Formatter tests
  static bool isDebug = false;
  static const eol = '';

  /// Apply formatting to the text
  String format(String text) {
    return formatEditUpdate(const TextEditingValue(text: ''), TextEditingValue(text: text)).text;
  }

  /// Strip applied formatting from the text
  String deformat(String text) {
    return text.digitsOnly();
  }

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

  /// Apply formatting to the text in a streaming manner.
  /// Use it instead of [formatEditUpdate] to simplify
  /// dealing with the cursor position.
  ///
  /// [processChar] is called for each character in the text and
  /// one more time when the end of the text is reached (with [eol]).
  TextEditingValue streamingEditUpdate(TextEditingContext context, ProcessingResult Function(String char) processChar) {
    final changeType = context.changeType;
    final oldValue = context.old;
    final newValue = context.preformatted;
    final newText = StringBuffer();
    final rawSelection = newValue.selection.end;
    int newSelection = rawSelection;
    for (int i = 0; i <= newValue.text.length; i++) {
      final char = i < newValue.text.length ? newValue.text[i] : eol;
      final result = processChar(char);
      // Here, the algorithm reaches a cursor position.
      // We need to adjust this position according to the new formatting.
      // - insertion: move cursor to the end of the added sequence
      // - erasure: no adjustment is needed because all formatting changes
      //   are performed after the removed substring (after the cursor)
      final reached = i == rawSelection - 1 || i == rawSelection && i == newValue.text.length;
      final inserting = changeType.isInsert;
      if (reached && inserting) {
        newSelection = newText.length + result.cursorShift;
      }
      newText.write(result.sequence);
    }
    final text = newText.toString();
    // If an attempt to delete the next character has no effect,
    // it means that this character is a part of formatting.
    // So, we need to move the cursor one step forward to let
    // a user continue erasing.
    // TODO: compare text[newSelection] to change.deleted[0]
    if (changeType == ChangeType.delete && text == oldValue.text && newSelection < text.length) {
      newSelection++;
    }
    newSelection = min(newSelection, text.length);
    printTestCase(oldValue, newValue, text, newSelection);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: newSelection));
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final changeType = getChange(oldValue, newValue).type;
    final context = TextEditingContext(old: oldValue, edited: newValue, preformatted: newValue, changeType: changeType);
    try {
      return formatUpdate(context);
    } catch (e) {
      if (e is CancelException) {
        return oldValue;
      }
      rethrow;
    }
  }

  TextEditingValue formatUpdate(TextEditingContext context);
}
