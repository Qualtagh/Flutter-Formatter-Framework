import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/types/matchers.dart';
import 'package:flutter_formatter_framework/types/stream_step_result.dart';
import 'package:flutter_formatter_framework/util/streaming_edit_update.dart';
import 'package:flutter_formatter_framework/util/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_util.dart';

void main() {
  initializeFormatterTests();
  group('Formatter.withFunction', () {
    final everyThirdCharFormatter = Formatter.withFunction((context) {
      int i = 0;
      return streamingEditUpdate(context, (char) {
        if (!Matchers.digits(char)) {
          return StreamStepResult(sequence: '');
        }
        try {
          return StreamStepResult(sequence: i > 0 && i % 3 == 0 && char != eol ? ' $char' : char);
        } finally {
          i++;
        }
      });
    }, (text) => text.digitsOnly());
    final t = makeSimpleTestFunction(formatter: everyThirdCharFormatter);
    test('format', () {
      t('', '1234567890', '123 456 789 0');
      t('1234567890', '1234', '123 4');
      t('123 4', '123 456', '123 456');
    });
  });
}
