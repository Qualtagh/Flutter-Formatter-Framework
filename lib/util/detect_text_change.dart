import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/types/change.dart';
import 'package:flutter_formatter_framework/types/change_type.dart';

/// Detect a text change
Change detectTextChange(TextEditingValue oldValue, TextEditingValue newValue) {
  final oldText = oldValue.text;
  final newText = newValue.text;
  final oldStart = min(max(0, oldValue.selection.start), oldText.length);
  final oldEnd = min(max(0, oldValue.selection.end), oldText.length);
  final newPos = min(max(0, newValue.selection.start), newText.length);
  final isSelected = oldStart < oldEnd;
  if (isSelected) {
    final selectedText = oldText.substring(oldStart, oldEnd);
    if (oldStart == newPos &&
        oldText.length > newText.length &&
        oldText.substring(0, oldStart) == newText.substring(0, newPos) &&
        oldText.substring(oldEnd) == newText.substring(newPos)) {
      return Change(
        type: ChangeType.clear,
        deletedAt: oldStart,
        deleted: selectedText,
        insertedAt: oldStart,
        inserted: '',
      );
    }
    if (oldStart < newPos &&
        oldText.substring(0, oldStart) == newText.substring(0, oldStart) &&
        oldText.substring(oldEnd) == newText.substring(newPos)) {
      return Change(
        type: ChangeType.replace,
        deletedAt: oldStart,
        deleted: selectedText,
        insertedAt: oldStart,
        inserted: newText.substring(oldStart, newPos),
      );
    }
    final selectionLength = oldEnd - oldStart;
    final movedTo = newPos - selectionLength;
    final movedBack = movedTo < oldStart;
    final (textA, textB) = movedBack ? (oldText, newText) : (newText, oldText);
    // Selected sequence in the old text: 0 <= oldStart < oldEnd <= length
    // Moved sequence in the new text: 0 <= movedTo < newPos <= length
    if (oldEnd != newPos &&
        movedTo >= 0 &&
        oldText.length == newText.length &&
        selectedText == newText.substring(movedTo, newPos) &&
        oldText.substring(0, min(oldStart, movedTo)) == newText.substring(0, min(oldStart, movedTo)) &&
        textA.substring(min(oldStart, movedTo), max(oldStart, movedTo)) ==
            textB.substring(min(oldEnd, newPos), max(oldEnd, newPos)) &&
        oldText.substring(max(oldEnd, newPos)) == newText.substring(max(oldEnd, newPos))) {
      return Change(
        type: ChangeType.move,
        deletedAt: oldStart,
        deleted: selectedText,
        insertedAt: movedTo,
        inserted: selectedText,
      );
    }
    return Change(type: ChangeType.undo, deletedAt: 0, deleted: oldText, insertedAt: 0, inserted: newText);
  }
  final lengthDelta = oldText.length - newText.length;
  if (oldStart == newPos &&
      lengthDelta > 0 &&
      oldText.substring(0, oldStart) == newText.substring(0, newPos) &&
      oldText.substring(oldStart + lengthDelta) == newText.substring(newPos)) {
    return Change(
      type: ChangeType.delete,
      deletedAt: oldStart,
      deleted: oldText.substring(oldStart, oldStart + lengthDelta),
      insertedAt: oldStart,
      inserted: '',
    );
  }
  if (oldStart > newPos &&
      oldText.substring(0, newPos) == newText.substring(0, newPos) &&
      oldText.substring(oldStart) == newText.substring(newPos)) {
    return Change(
      type: ChangeType.erase,
      deletedAt: newPos,
      deleted: oldText.substring(newPos, oldStart),
      insertedAt: newPos,
      inserted: '',
    );
  }
  if (oldStart < newPos &&
      oldText.substring(0, oldStart) == newText.substring(0, oldStart) &&
      oldText.substring(oldStart) == newText.substring(newPos)) {
    return Change(
      type: ChangeType.insert,
      deletedAt: oldStart,
      deleted: '',
      insertedAt: oldStart,
      inserted: newText.substring(oldStart, newPos),
    );
  }
  if (oldStart < newPos &&
      oldText.substring(0, oldStart) == newText.substring(0, oldStart) &&
      (newPos > oldText.length || oldText.substring(newPos) == newText.substring(newPos))) {
    return Change(
      type: ChangeType.overtype,
      deletedAt: oldStart,
      deleted: oldText.substring(oldStart, min(newPos, oldText.length)),
      insertedAt: oldStart,
      inserted: newText.substring(oldStart, newPos),
    );
  }
  return Change(type: ChangeType.undo, deletedAt: 0, deleted: oldText, insertedAt: 0, inserted: newText);
}
