import 'package:collection/equality.dart';
import 'package:flutter_formatter_framework/formatters/chain_formatter.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/formatters/try_catch_formatter.dart';
import 'package:flutter_formatter_framework/types/cancel_exception.dart';
import 'package:flutter_formatter_framework/types/stream_step_result.dart';
import 'package:flutter_formatter_framework/util/streaming_edit_update.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_util.dart';

void main() {
  initializeFormatterTests();
  test('TryCatchFormatter', () {
    final called = <String>{};
    spyFormatter(message) => Formatter.withFunction((context) {
      called.add(message);
      return streamingEditUpdate(context, (char) {
        if (char == eol) {
          return StreamStepResult(sequence: ' $message');
        }
        return StreamStepResult(sequence: char);
      });
    });
    final formatter = ChainFormatter([
      spyFormatter('called 0'),
      TryCatchFormatter(
        ChainFormatter([
          spyFormatter('called 1'),
          spyFormatter('called 2'),
          Formatter.withFunction((context) {
            throw CancelException();
          }),
          spyFormatter('never called'),
        ]),
      ),
      spyFormatter('called finally'),
    ]);
    final t = makeSimpleTestFunction(formatter: formatter, checkFormat: false, checkDeformat: false);
    t('1234', '123', '1234 called finally');
    assert(const SetEquality().equals(called, {'called 0', 'called 1', 'called 2', 'called finally'}));
  });
}
