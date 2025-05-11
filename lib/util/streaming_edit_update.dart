import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/change_type.dart';
import 'package:flutter_formatter_framework/types/stream_step_result.dart';
import 'package:flutter_formatter_framework/types/text_editing_context.dart';
import 'package:flutter_formatter_framework/util/position_tracker.dart';

/// EOL (end of line) is returned from [streamingEditUpdate] to [processChar] when the end of the text is reached
const eol = '';

/// Apply formatting to the text in a streaming manner.
/// Use it instead of [formatEditUpdate] to simplify
/// dealing with the cursor position.
///
/// [processChar] is called for each character in the text and
/// one more time when the end of the text is reached (with [eol]).
TextEditingValue streamingEditUpdate(TextEditingContext context, StreamStepResult Function(String char) processChar) {
  final change = context.change;
  final newValue = context.preformatted;
  final newText = StringBuffer();
  final positions = PositionListTracker([
    newValue.selection.start,
    newValue.selection.end,
    newValue.composing.start,
    newValue.composing.end,
  ]);
  for (int i = 0; i <= newValue.text.length; i++) {
    final char = i < newValue.text.length ? newValue.text[i] : eol;
    final result = processChar(char);
    isReached(pos) => i == pos - 1 || i == pos && i == newValue.text.length;
    final inserting = change.type.isInsert;
    // Here, the algorithm reaches the cursor position.
    // We need to adjust this position according to the new formatting.
    // - insertion: move cursor to the end of the added sequence
    // - erasure: no adjustment is needed because all formatting changes
    //   are performed after the removed substring (after the cursor)
    if (inserting) {
      final newPos = newText.length + result.cursorShift;
      positions.updateIfOld(isReached, (_) => newPos);
    }
    newText.write(result.sequence);
  }
  final text = newText.toString();
  // If an attempt to delete the next character has no effect,
  // it means that this character is a part of formatting.
  // So, we need to move the cursor one step forward to let
  // a user continue erasing.
  if (change.type == ChangeType.delete) {
    resistsDeletion(pos) => 0 <= pos && pos < text.length && text[pos] == change.deleted[0];
    positions.updateIfNew(resistsDeletion, (pos) => pos + 1);
  }
  bool isOutOfBounds(pos) => pos > text.length;
  positions.updateIfNew(isOutOfBounds, (_) => text.length);
  return TextEditingValue(
    text: text,
    selection: TextSelection(
      baseOffset: positions[0],
      extentOffset: positions[1],
      affinity: newValue.selection.affinity,
      isDirectional: newValue.selection.isDirectional,
    ),
    composing: positions[2] == positions[3] ? TextRange.empty : TextRange(start: positions[2], end: positions[3]),
  );
}
