import 'package:flutter_formatter_framework/formatters/mask_formatter.dart';
import 'package:flutter_formatter_framework/types/matchers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_util.dart';

void main() {
  initializeFormatterTests();
  group('MaskFormatter', () {
    final formatter = MaskFormatter(mask: '##-####-#######-###');
    final t = makeTestFunction(formatter: formatter);
    test('sequentially write digits', () {
      t('', 0, 0, '1', 1, '1', 1);
      t('1', 1, 1, '12', 2, '12-', 3);
      t('12-', 3, 3, '12-3', 4, '12-3', 4);
      t('12-3', 4, 4, '12-34', 5, '12-34', 5);
    });
    test('erase digits', () {
      // From 5
      t('12-34', 5, 5, '12-3', 4, '12-3', 4);
      t('12-3', 4, 4, '12-', 3, '12-', 3);
      t('12-', 3, 3, '12', 2, '12', 2);
      t('12', 2, 2, '1', 1, '1', 1);
      t('1', 1, 1, '', 0, '', 0);
      // From 4
      t('12-34', 4, 4, '12-4', 3, '12-4', 3);
      // When erasing the dash, just move the cursor back
      t('12-4', 3, 3, '124', 2, '12-4', 2);
      t('12-4', 2, 2, '1-4', 1, '14', 1);
      t('14-', 1, 1, '4-', 0, '4', 0);
      // From 3: when erasing the dash, just move the cursor back
      t('12-34', 3, 3, '1234', 2, '12-34', 2);
      t('12-34', 2, 2, '1-34', 1, '13-4', 1);
      t('13-4', 1, 1, '3-4', 0, '34', 0);
      // From 2
      t('12-34', 2, 2, '1-34', 1, '13-4', 1);
      t('13-4', 1, 1, '3-4', 0, '34', 0);
      // From 1
      t('12-34', 1, 1, '2-34', 0, '23-4', 0);
    });
    test('delete (forward)', () {
      // From 4
      t('12-34', 4, 4, '12-3', 4, '12-3', 4);
      // From 3
      t('12-34', 3, 3, '12-4', 3, '12-4', 3);
      t('12-4', 3, 3, '12-', 3, '12-', 3);
      // From 2: just move the cursor forward, don't remove dash
      t('12-34', 2, 2, '1234', 2, '12-34', 3);
      // From 1
      t('12-34', 1, 1, '1-34', 1, '13-4', 1);
      t('13-4', 1, 1, '1-4', 1, '14', 1);
      t('14-', 1, 1, '1-', 1, '1', 1);
      // From 0
      t('12-34', 0, 0, '2-34', 0, '23-4', 0);
      t('23-4', 0, 0, '3-4', 0, '34', 0);
      t('34-', 0, 0, '4-', 0, '4', 0);
      t('4', 0, 0, '', 0, '', 0);
    });
    test('ctrl+backspace', () {
      // From 5
      t('12-34', 5, 5, '12-', 3, '12-', 3);
      t('12-', 3, 3, '12', 2, '12', 2);
      t('12', 2, 2, '', 0, '', 0);
      // From 4
      t('12-34', 4, 4, '12-4', 3, '12-4', 3);
      t('12-4', 3, 3, '124', 2, '12-4', 2);
      t('12-4', 2, 2, '-4', 0, '4', 0);
      // From 3
      t('12-34', 3, 3, '1234', 2, '12-34', 2);
      t('12-34', 2, 2, '-34', 0, '34', 0);
      // From 2
      t('12-34', 2, 2, '-34', 0, '34', 0);
      // From 1
      t('12-34', 1, 1, '2-34', 0, '23-4', 0);
    });
    test('ctrl+delete', () {
      // From 4
      t('12-34', 4, 4, '12-3', 4, '12-3', 4);
      // From 3
      t('12-34', 3, 3, '12-', 3, '12-', 3);
      // From 2
      t('12-34', 2, 2, '1234', 2, '12-34', 3);
      // From 1
      t('12-34', 1, 1, '1-34', 1, '13-4', 1);
      t('13-4', 1, 1, '1-4', 1, '14', 1);
      t('14-', 1, 1, '1-', 1, '1', 1);
      // From 0
      t('12-34', 0, 0, '-34', 0, '34', 0);
      t('34-', 0, 0, '-', 0, '', 0);
    });
    test('type in the middle', () {
      // Length 3
      t('12-4', 3, 3, '12-34', 4, '12-34', 4);
      t('12-4', 2, 2, '123-4', 3, '12-34', 4);
      t('13-4', 1, 1, '123-4', 2, '12-34', 2);
      t('23-4', 0, 0, '123-4', 1, '12-34', 1);
      // Length 2
      t('12-', 2, 2, '123-', 3, '12-3', 4);
      t('13-', 1, 1, '123-', 2, '12-3', 2);
      t('23-', 0, 0, '123-', 1, '12-3', 1);
      // Length 1
      t('2', 0, 0, '12', 1, '12-', 1);
    });
    test('undo', () {
      // Undo operation produces varying offset of the newValue,
      // so the final result may vary too and thus is difficult to test.
      // Examples:
      // - undo of several digits removal resets cursor to the end
      // - undo of a single digit addition in the middle keeps cursor untouched
      // But users don't have particular expectations about the cursor position
      // when undoing typing, so we don't test this case thoroughly.
      // Let's simply put the cursor to the end when newValue's cursor is at the end.
      // In other cases, let the behaviour be undefined.
      t('12-78', 0, 0, '12-3456-78', 10, '12-3456-78', 10);
    });
    test('erase selection', () {
      // Between dashes (touching dashes)
      t('12-3456-78', 3, 7, '12--78', 3, '12-78', 3);
      // Inside dashes (not touching dashes)
      t('12-3456-78', 4, 6, '12-36-78', 4, '12-3678', 4);
      // After a dash
      t('12-3456-78', 3, 5, '12-56-78', 3, '12-5678', 3);
      // Including a dash and after
      t('12-3456-78', 2, 5, '1256-78', 2, '12-5678', 2);
      // Before, including, and after a dash
      t('12-3456-78', 1, 5, '156-78', 1, '15-678', 1);
      // Before and including a dash
      t('12-3456-78', 1, 3, '13456-78', 1, '13-4567-8', 1);
      // Before a dash
      t('12-3456-78', 1, 2, '1-3456-78', 1, '13-4567-8', 1);
      // Just a dash: no removal, move a cursor to the start of the selection
      t('12-3456-78', 2, 3, '123456-78', 2, '12-3456-78', 2);
      // Interval including 2 dashes
      t('12-3456-78', 1, 9, '18', 1, '18', 1);
      // Up to a dash
      t('12-3456-78', 8, 10, '12-3456-', 8, '12-3456-', 8);
      // Including a dash
      t('12-3456-78', 7, 10, '12-3456', 7, '12-3456', 7);
    });
    test('type when selected', () {
      // Instead of a dash
      t('12-3456-78', 2, 3, '1203456-78', 3, '12-0345-678', 4);
      // Instead of a dash and the next digit
      t('12-3456-78', 2, 4, '120456-78', 3, '12-0456-78', 4);
      // Instead of a dash and the previous digit
      t('12-3456-78', 1, 3, '103456-78', 2, '10-3456-78', 2);
      // Instead of a dash and the 2 surrounding digits
      t('12-3456-78', 1, 4, '10456-78', 2, '10-4567-8', 2);
      // Between dashes (touching)
      t('12-3456-78', 3, 7, '12-0-78', 4, '12-078', 4);
      // Inside dashes (not touching)
      t('12-3456-78', 4, 6, '12-306-78', 5, '12-3067-8', 5);
    });
    test('insert copied sequence', () {
      // To empty field
      t('', 0, 0, '12345678', 8, '12-3456-78', 10);
      // To the middle
      t('12-3456-78', 5, 5, '12-341234567856-78', 13, '12-3412-3456785-678', 14);
      // After a dash
      t('12-', 3, 3, '12-3456', 7, '12-3456-', 8);
      // Replace a sequence
      t('12-3456-78', 3, 7, '12-12345678-78', 11, '12-1234-567878', 12);
      // Replace a sequence, but only one character changes inside
      t('12-3456-78', 3, 7, '12-3056-78', 7, '12-3056-78', 7);
      // Insert dashes
      t('12-34', 3, 3, '12-----34', 7, '12-34', 3);
      t('12-34', 2, 2, '12-----34', 6, '12-34', 3);
    });
    // Cancel any overflowing inputs
    test('overflow', () {
      // Type at the end
      t('12-3456-7812345-678', 19, 19, '12-3456-7812345-6781', 20);
      // Type in the middle
      t('12-3456-7812345-678', 0, 0, '112-3456-7812345-678', 1);
      // Replace a dash
      t('12-3456-7812345-678', 2, 3, '1203456-7812345-678', 3);
      // Replace a sequence
      t('12-3456-7812345-678', 0, 2, '12345678-3456-7812345-678', 8);
    });
  });

  group('MaskFormatter with fallbackMap at the end', () {
    final formatter = MaskFormatter(
      mask: '##.@@',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
    );
    final t = makeTestFunction(formatter: formatter);
    test('finish with fallback', () {
      // Don't move the cursor
      t('12', 2, 2, '12.', 3, '12.00', 3);
      t('12.', 3, 3, '12.0', 4, '12.00', 4);
      t('12.0', 4, 4, '12.00', 5, '12.00', 5);
      // Type according to the fallback
      t('12.00', 2, 2, '120.00', 3, '12.00', 4);
      t('12.00', 2, 2, '12..00', 3, '12.00', 3);
      t('12.00', 3, 3, '12..00', 4, '12.00', 3);
      t('12.00', 3, 3, '12.000', 4, '12.00', 4);
      t('12.00', 4, 4, '12.000', 5, '12.00', 5);
      t('12.00', 5, 5, '12.000', 6, '12.00', 5);
      // Type according to the mask
      t('12.00', 2, 2, '129.00', 3, '12.90', 4);
      t('12.00', 3, 3, '12.900', 4, '12.90', 4);
      t('12.00', 4, 4, '12.090', 5, '12.09', 5);
      t('12.00', 5, 5, '12.009', 6, '12.00', 5);
      // Type non-matching characters
      t('12.00', 2, 2, '12a.00', 3, '12.00', 2);
      t('12.00', 3, 3, '12.a00', 4, '12.00', 3);
      t('12.00', 4, 4, '12.0a0', 5, '12.00', 4);
      t('12.00', 5, 5, '12.00a', 6, '12.00', 5);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12.00', 4, 4, '12.0', 3, '12.0', 3);
      t('12.00', 2, 2, '1.00', 1, '10.0', 1);
      // Erase a dot
      t('12.0', 3, 3, '120', 2, '12.0', 2);
    });
  });

  group('MaskFormatter with fallbackMap in the middle', () {
    final formatter = MaskFormatter(
      mask: '##-@@-##',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
    );
    final t = makeTestFunction(formatter: formatter);
    test('type inside a fallback region', () {
      // Don't move the cursor
      t('12', 2, 2, '12-', 3, '12-00-', 3);
      t('12-', 3, 3, '12-0', 4, '12-00-', 4);
      t('12-0', 4, 4, '12-00', 5, '12-00-', 6);
      // Type according to the fallback
      t('12-00', 2, 2, '120-00', 3, '12-00-0', 4);
      t('12-00', 2, 2, '12--00', 3, '12-00-', 3);
      t('12-00', 3, 3, '12--00', 4, '12-00-', 3);
      t('12-00', 3, 3, '12-000', 4, '12-00-0', 4);
      t('12-00', 4, 4, '12-000', 5, '12-00-0', 5);
      t('12-00', 5, 5, '12-000', 6, '12-00-0', 7);
      // Type according to the mask
      t('12-00', 2, 2, '129-00', 3, '12-90-0', 4);
      t('12-00', 3, 3, '12-900', 4, '12-90-0', 4);
      t('12-00', 4, 4, '12-090', 5, '12-09-0', 5);
      t('12-00', 5, 5, '12-009', 6, '12-00-9', 7);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12-00', 4, 4, '12-0', 3, '12-0', 3);
      t('12-00-', 4, 4, '12-0-', 3, '12-0', 3);
      t('12-00', 2, 2, '1-00', 1, '10-0', 1);
      // Erase a dash
      t('12-0', 3, 3, '120', 2, '12-0', 2);
    });
  });

  group('MaskFormatter (lazy)', () {
    final formatter = MaskFormatter(
      mask: '##-@@-##',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
      completionPolicy: CompletionPolicy.lazy,
    );
    final t = makeTestFunction(formatter: formatter);
    test('type inside a fallback region', () {
      t('1', 1, 1, '12', 2, '12', 2);
      t('12', 2, 2, '12-', 3, '12-', 3);
      t('12-', 3, 3, '12-0', 4, '12-0', 4);
      t('12-0', 4, 4, '12-00', 5, '12-00', 5);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12-00', 4, 4, '12-0', 3, '12-0', 3);
      t('12-00-', 4, 4, '12-0-', 3, '12-0', 3);
      t('12-00', 2, 2, '1-00', 1, '10-0', 1);
      // Erase a dash
      t('12-0', 3, 3, '120', 2, '12-0', 2);
    });
  });

  group('MaskFormatter (eager)', () {
    final formatter = MaskFormatter(
      mask: '##-@@-##',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
      completionPolicy: CompletionPolicy.eager,
    );
    final t = makeTestFunction(formatter: formatter);
    test('type inside a fallback region', () {
      t('1', 1, 1, '12', 2, '12-00-', 3);
      t('12', 2, 2, '12-', 3, '12-00-', 3);
      t('12-', 3, 3, '12-0', 4, '12-00-', 4);
      t('12-0', 4, 4, '12-00', 5, '12-00-', 6);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12-00', 4, 4, '12-0', 3, '12-0', 3);
      t('12-00-', 4, 4, '12-0-', 3, '12-0', 3);
      t('12-00', 2, 2, '1-00', 1, '10-0', 1);
      // Erase a dash
      t('12-0', 3, 3, '120', 2, '12-0', 2);
    });
  });

  group('MaskFormatter (lazy if fallback)', () {
    final formatter = MaskFormatter(
      mask: '##-@@-##',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
      completionPolicy: CompletionPolicy.lazyIfFallback,
    );
    final t = makeTestFunction(formatter: formatter);
    test('type inside a fallback region', () {
      t('1', 1, 1, '12', 2, '12-', 3);
      t('12', 2, 2, '12-', 3, '12-', 3);
      t('12-', 3, 3, '12-0', 4, '12-0', 4);
      t('12-0', 4, 4, '12-00', 5, '12-00-', 6);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12-00', 4, 4, '12-0', 3, '12-0', 3);
      t('12-00-', 4, 4, '12-0-', 3, '12-0', 3);
      t('12-00', 2, 2, '1-00', 1, '10-0', 1);
      // Erase a dash
      t('12-0', 3, 3, '120', 2, '12-0', 2);
    });
  });

  group('MaskFormatter (eager if fallback)', () {
    final formatter = MaskFormatter(
      mask: '##-@@-##',
      maskCharMap: {'#': Matchers.digits, '@': Matchers.digits},
      fallbackMap: {'@': '0'},
      overflowPolicy: OverflowPolicy.truncate,
      completionPolicy: CompletionPolicy.eagerIfFallback,
    );
    final t = makeTestFunction(formatter: formatter);
    test('type inside a fallback region', () {
      t('1', 1, 1, '12', 2, '12', 2);
      t('12', 2, 2, '12-', 3, '12-00', 3);
      t('12-', 3, 3, '12-0', 4, '12-00', 4);
      t('12-0', 4, 4, '12-00', 5, '12-00', 5);
    });
    test('allow erasing', () {
      // Erase a digit
      t('12-00', 4, 4, '12-0', 3, '12-0', 3);
      t('12-00-', 4, 4, '12-0-', 3, '12-0', 3);
      t('12-00', 2, 2, '1-00', 1, '10-0', 1);
      // Erase a dash
      t('12-0', 3, 3, '120', 2, '12-0', 2);
    });
  });
}
