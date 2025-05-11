import 'package:flutter/semantics.dart';
import 'package:flutter_formatter_framework/formatters/change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  t(
    String old,
    int start,
    int end,
    String edited,
    int position,
    ChangeType expectedType,
    int deletedAt,
    String deleted,
    int insertedAt,
    String inserted,
  ) {
    final oldValue = TextEditingValue(text: old, selection: TextSelection(baseOffset: start, extentOffset: end));
    final newValue = TextEditingValue(text: edited, selection: TextSelection.collapsed(offset: position));
    final expected = Change(
      type: expectedType,
      deletedAt: deletedAt,
      deleted: deleted,
      insertedAt: insertedAt,
      inserted: inserted,
    );
    expect(getChange(oldValue, newValue), expected);
  }

  group('getChangeType', () {
    test('basic', () {
      // Type a letter
      t('lorem ipsum', 1, 1, 'lNorem ipsum', 2, ChangeType.insert, 1, '', 1, 'N');
      // Paste a sequence
      t('lorem ipsum', 1, 1, 'lSEQUENCEorem ipsum', 9, ChangeType.insert, 1, '', 1, 'SEQUENCE');
      // Replace a letter (INSERT button toggled to overtype mode)
      t('lorem ipsum', 1, 1, 'lNrem ipsum', 2, ChangeType.overtype, 1, 'o', 1, 'N');
      // Replace a sequence (paste in overtype mode)
      t('lorem ipsum', 1, 1, 'lSEQUENCEum', 9, ChangeType.overtype, 1, 'orem ips', 1, 'SEQUENCE');
      // Replace and type further (overtype mode)
      t('lorem ipsum', 8, 8, 'lorem ipSEQUENCE', 16, ChangeType.overtype, 8, 'sum', 8, 'SEQUENCE');
      // Erase a character (backspace)
      t('lorem ipsum', 5, 5, 'lore ipsum', 4, ChangeType.erase, 4, 'm', 4, '');
      // Erase a word (ctrl+backspace)
      t('lorem ipsum', 5, 5, ' ipsum', 0, ChangeType.erase, 0, 'lorem', 0, '');
      // Delete a character (delete button)
      t('lorem ipsum', 6, 6, 'lorem psum', 6, ChangeType.delete, 6, 'i', 6, '');
      // Delete a word (ctrl+delete)
      t('lorem ipsum', 6, 6, 'lorem ', 6, ChangeType.delete, 6, 'ipsum', 6, '');
      // Clear a selection
      t('lorem ipsum', 2, 5, 'lo ipsum', 2, ChangeType.clear, 2, 'rem', 2, '');
      // Replace a selection with one character
      t('lorem ipsum', 2, 5, 'loN ipsum', 3, ChangeType.replace, 2, 'rem', 2, 'N');
      // Replace a selection with a sequence
      t('lorem ipsum', 2, 5, 'loSEQUENCE ipsum', 10, ChangeType.replace, 2, 'rem', 2, 'SEQUENCE');
      // Move a selected sequence back
      t('lorem ipsum', 2, 5, 'remlo ipsum', 3, ChangeType.move, 2, 'rem', 0, 'rem');
      // Move a selected sequence forward
      t('lorem ipsum', 2, 5, 'lo remipsum', 6, ChangeType.move, 2, 'rem', 3, 'rem');
      // Undo the last change
      t('lorem ipsum', 1, 1, 'alter ego', 9, ChangeType.undo, 0, 'lorem ipsum', 0, 'alter ego');
      // Undo while selected
      t('lorem ipsum', 2, 5, 'alter ego', 9, ChangeType.undo, 0, 'lorem ipsum', 0, 'alter ego');
    });
    test('tricky', () {
      // Replace with the same sequence
      t('aaaaa', 1, 3, 'aaaaa', 3, ChangeType.replace, 1, 'aa', 1, 'aa');
      // Move back
      t('aaaaa', 1, 3, 'aaaaa', 2, ChangeType.move, 1, 'aa', 0, 'aa');
      // Move forward
      t('aaaaa', 1, 3, 'aaaaa', 4, ChangeType.move, 1, 'aa', 2, 'aa');
      // Move, so it ends where it started
      t('aaaaa', 2, 4, 'aaaaa', 2, ChangeType.move, 2, 'aa', 0, 'aa');
    });
  });
}
