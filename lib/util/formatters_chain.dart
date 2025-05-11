import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:flutter_formatter_framework/formatters/chain_formatter.dart';

class FormattersChain extends DelegatingList<TextInputFormatter> {
  FormattersChain(List<TextInputFormatter> formatters) : super([ChainFormatter(formatters)]);
}
