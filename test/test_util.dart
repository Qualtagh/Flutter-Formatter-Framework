import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/chain_formatter.dart';
import 'package:flutter_formatter_framework/formatters/formatter.dart';
import 'package:flutter_formatter_framework/util/detect_text_change.dart';
import 'package:flutter_formatter_framework/util/string_extension.dart';
import 'package:flutter_test/flutter_test.dart';

/// If [expectedValue] and [expectedPosition] are omitted, the test checks
/// for a cancellation of the change (i.e. that the formatter returns the old value).
typedef TestFunction =
    void Function(
      String oldValue,
      int start,
      int end,
      String newValue,
      int position, [
      String? expectedValue,
      int? expectedPosition,
    ]);

typedef SimpleTestFunction = void Function(String oldValue, String newValue, String expectedValue);

void compareEditingValues(TextEditingValue actual, TextEditingValue expected) {
  // Only text and selection position are checked for now.
  // Affinity and composing are not strictly enforced by the framework.
  expect(actual.text, expected.text);
  expect(actual.selection.baseOffset, expected.selection.baseOffset);
  expect(actual.selection.extentOffset, expected.selection.extentOffset);
}

TestFunction makeTestFunction({
  required Formatter formatter,
  bool checkCursorPosition = true,
  bool checkFormat = true,
  bool checkDeformat = true,
  TextInputFormatter? priorFormatter,
}) {
  return (
    String oldValue,
    int start,
    int end,
    String newValue,
    int position, [
    String? expectedValue,
    int? expectedPosition,
  ]) {
    final oldInput = TextEditingValue(text: oldValue, selection: TextSelection(baseOffset: start, extentOffset: end));
    final newInput = TextEditingValue(text: newValue, selection: TextSelection.collapsed(offset: position));
    final inserting = detectTextChange(oldInput, newInput).type.isInsert;
    final formatters = [
      formatter,
      if (priorFormatter != null) ChainFormatter([priorFormatter, formatter]),
    ];
    for (final currentFormatter in formatters) {
      final actual = currentFormatter.formatEditUpdate(oldInput, newInput);
      final expected =
          expectedValue == null || expectedPosition == null
              ? oldInput
              : TextEditingValue(text: expectedValue, selection: TextSelection.collapsed(offset: expectedPosition));
      if (checkCursorPosition) {
        compareEditingValues(actual, expected);
      } else {
        expect(actual.text, expected.text);
      }
      if (checkFormat && inserting) {
        expect(currentFormatter.format(newValue), expectedValue ?? '');
      }
      if (checkDeformat) {
        // TODO: only suitable for MaskFormatter, the output of other formatters may be more complex
        expect(currentFormatter.deformat(actual.text), actual.text.digitsOnly());
      }
    }
  };
}

/// This one assumes that cursor position works well and only concentrates on the text value
SimpleTestFunction makeSimpleTestFunction({
  required Formatter formatter,
  TextInputFormatter? priorFormatter,
  bool checkFormat = true,
  bool checkDeformat = true,
}) {
  final t = makeTestFunction(
    formatter: formatter,
    checkCursorPosition: false,
    priorFormatter: priorFormatter,
    checkFormat: checkFormat,
    checkDeformat: checkDeformat,
  );
  return (String oldValue, String newValue, String expectedValue) =>
      t(oldValue, 0, oldValue.length, newValue, newValue.length, expectedValue, expectedValue.length);
}

void initializeFormatterTests() {
  setUpAll(() => Formatter.isDebug = true);
  tearDownAll(() => Formatter.isDebug = false);
}
