/// The type of text change after editing by user.
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
  /// (currently not supported in Flutter and NOT detected by [detectTextChange] yet).
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
