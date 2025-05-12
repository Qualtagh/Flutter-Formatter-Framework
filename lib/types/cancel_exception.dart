/// Throw it from any formatter to cancel the formatting process.
///
/// It may be more convenient than the standard Flutter way of
/// returning the original text ([oldInput]) because this exception
/// prevents processing by the remaining formatters in the chain.
///
/// See also [TryCatchFormatter] which provides more control on error flows.
class CancelException implements Exception {}
