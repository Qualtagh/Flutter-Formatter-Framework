import 'package:flutter/semantics.dart';
import 'package:flutter_formatter_framework/formatters/change_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  t(String old, int start, int end, String edited, int position, ChangeType expected) {
    final oldValue = TextEditingValue(text: old, selection: TextSelection(baseOffset: start, extentOffset: end));
    final newValue = TextEditingValue(text: edited, selection: TextSelection.collapsed(offset: position));
    expect(getChangeType(oldValue, newValue), expected);
  }

  group('getChangeType', () {
    test('basic', () {
      // Type a letter
      t('lorem ipsum', 1, 1, 'lNorem ipsum', 2, ChangeType.insert);
      // Paste a sequence
      t('lorem ipsum', 1, 1, 'lSEQUENCEorem ipsum', 9, ChangeType.insert);
      // Replace a letter (INSERT button toggled to overtype mode)
      t('lorem ipsum', 1, 1, 'lNrem ipsum', 2, ChangeType.overtype);
      // Replace a sequence (paste in overtype mode)
      t('lorem ipsum', 1, 1, 'lSEQUENCEum', 9, ChangeType.overtype);
      // Replace and type further (overtype mode)
      t('lorem ipsum', 8, 8, 'lorem ipSEQUENCE', 16, ChangeType.overtype);
      // Erase a character (backspace)
      t('lorem ipsum', 5, 5, 'lore ipsum', 4, ChangeType.erase);
      // Erase a word (ctrl+backspace)
      t('lorem ipsum', 5, 5, ' ipsum', 0, ChangeType.erase);
      // Delete a character (delete button)
      t('lorem ipsum', 6, 6, 'lorem psum', 6, ChangeType.delete);
      // Delete a word (ctrl+delete)
      t('lorem ipsum', 6, 6, 'lorem ', 6, ChangeType.delete);
      // Clear a selection
      t('lorem ipsum', 2, 5, 'lo ipsum', 2, ChangeType.clear);
      // Replace a selection with one character
      t('lorem ipsum', 2, 5, 'loN ipsum', 3, ChangeType.replace);
      // Replace a selection with a sequence
      t('lorem ipsum', 2, 5, 'loSEQUENCE ipsum', 10, ChangeType.replace);
      // Move a selected sequence back
      t('lorem ipsum', 2, 5, 'remlo ipsum', 3, ChangeType.move);
      // Move a selected sequence forward
      t('lorem ipsum', 2, 5, 'lo remipsum', 6, ChangeType.move);
      // Undo the last change
      t('lorem ipsum', 1, 1, 'alter ego', 9, ChangeType.undo);
      // Undo while selected
      t('lorem ipsum', 2, 5, 'alter ego', 9, ChangeType.undo);
    });
    test('tricky', () {
      // Replace with the same sequence
      t('aaaaa', 1, 3, 'aaaaa', 3, ChangeType.replace);
      // Move back
      t('aaaaa', 1, 3, 'aaaaa', 2, ChangeType.move);
      // Move forward
      t('aaaaa', 1, 3, 'aaaaa', 4, ChangeType.move);
      // Move, so it ends where it started
      t('aaaaa', 2, 4, 'aaaaa', 2, ChangeType.move);
    });
  });
}
