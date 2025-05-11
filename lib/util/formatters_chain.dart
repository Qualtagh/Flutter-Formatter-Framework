import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/chain_formatter.dart';

/// A shorthand for creating a chain of formatters.
/// Usage example:
/// ```dart
/// TextFormField(
///   initialValue: '12/12/2023',
///   inputFormatters: FormattersChain([
///     FilteringTextInputFormatter.digitsOnly,
///     MaskFormatter('##/##/####'),
///   ]),
/// )
/// ```
/// Use it instead of simply passing a list of formatters because
/// this approach provides a more detailed [TextEditingContext] to each formatter.
class FormattersChain extends DelegatingList<TextInputFormatter> {
  FormattersChain(List<TextInputFormatter> formatters) : super([ChainFormatter(formatters)]);
}
