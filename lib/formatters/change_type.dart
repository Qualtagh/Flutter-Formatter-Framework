import 'dart:math';

import 'package:flutter/services.dart';

enum ChangeType {
  /// Insert characters (type or paste): move cursor to the end of inserted sequence
  insert(true),

  /// Overtype a character (overwriting mode enabled by insert button):
  /// https://en.wikipedia.org/wiki/Insert_key
  /// (currently not supported in Flutter).
  /// Put cursor to the end of replaced sequence.
  overtype(true),

  /// Erase backward (backspace button): put cursor to the beginning of erased sequence
  erase(false),

  /// Erase forward (delete button): keep cursor at the same position
  delete(false),

  /// Replace selection: put cursor to the end of inserted sequence
  replace(true),

  /// Replace selection in overtype mode: put cursor to the end of replaced sequence
  /// (currently not supported in Flutter and NOT detected by [getChangeType] yet).
  /// The detection depends on how it will be implemented in Flutter.
  replaceOvertype(true),

  /// Clear selection: put cursor to the beginning of selected substring
  clear(false),

  /// Move selected sequence: put cursor to the end of moved sequence
  /// (currently not supported in Flutter)
  move(true),

  /// Undo the last operation: cursor position behaviour is undefined.
  /// It's usually put to the end of the text, but it's not guaranteed.
  /// Users don't expect a particular cursor position after undo, so it should be fine.
  /// This is a fallback for all other cases: any unrecognized change is treated as undo.
  undo(true);

  /// Whether to put the cursor to the end of changed part (true) or to the beginning (false).
  /// Mostly, same as: an insertion (true) or deletion (false). Undo is treated as insertion.
  final bool isInsert;

  const ChangeType(this.isInsert);
}

class Change {
  /// Change type
  final ChangeType type;

  /// Start position of deleted sequence (before insertion)
  final int deletedAt;

  /// Deleted sequence
  final String deleted;

  /// Start position of inserted sequence (after deletion)
  final int insertedAt;

  /// Inserted sequence
  final String inserted;

  Change({
    required this.type,
    required this.deletedAt,
    required this.deleted,
    required this.insertedAt,
    required this.inserted,
  });

  @override
  String toString() {
    return 'Change(type: $type, deletedAt: $deletedAt, deleted: "$deleted", insertedAt: $insertedAt, inserted: "$inserted")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Change) return false;
    return type == other.type &&
        deletedAt == other.deletedAt &&
        deleted == other.deleted &&
        insertedAt == other.insertedAt &&
        inserted == other.inserted;
  }

  @override
  int get hashCode {
    return type.hashCode ^ deletedAt.hashCode ^ deleted.hashCode ^ insertedAt.hashCode ^ inserted.hashCode;
  }
}

/// Detect a text change
Change getChange(TextEditingValue oldValue, TextEditingValue newValue) {
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
