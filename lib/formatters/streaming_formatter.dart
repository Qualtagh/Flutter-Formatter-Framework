import 'dart:core';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/change.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/formatters/text_editing_context.dart';

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

abstract class StreamingFormatter extends Formatter {
  /// EOL (end of line) is returned from [streamingEditUpdate] when the end of the text is reached
  static const eol = '';

  /// Apply formatting to the text in a streaming manner.
  /// Use it instead of [formatEditUpdate] to simplify
  /// dealing with the cursor position.
  ///
  /// [processChar] is called for each character in the text and
  /// one more time when the end of the text is reached (with [eol]).
  TextEditingValue streamingEditUpdate(TextEditingContext context, ProcessingResult Function(String char) processChar) {
    final change = context.change;
    final newValue = context.preformatted;
    final newText = StringBuffer();
    final rawSelection = newValue.selection.end;
    int newSelection = rawSelection;
    for (int i = 0; i <= newValue.text.length; i++) {
      final char = i < newValue.text.length ? newValue.text[i] : eol;
      final result = processChar(char);
      final reached = i == rawSelection - 1 || i == rawSelection && i == newValue.text.length;
      final inserting = change.type.isInsert;
      // Here, the algorithm reaches the cursor position.
      // We need to adjust this position according to the new formatting.
      // - insertion: move cursor to the end of the added sequence
      // - erasure: no adjustment is needed because all formatting changes
      //   are performed after the removed substring (after the cursor)
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
    if (change.type == ChangeType.delete && newSelection < text.length && text[newSelection] == change.deleted[0]) {
      newSelection++;
    }
    newSelection = min(newSelection, text.length);
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: newSelection));
  }
}
