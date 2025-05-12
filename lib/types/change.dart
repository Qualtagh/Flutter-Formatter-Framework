import 'package:flutter_formatter_framework/types/change_type.dart';

/// Represents a change in text editing.
class Change {
  /// Change type
  final ChangeType type;

  /// Start position of deleted sequence (before insertion)
  final int deletedAt;

  /// Deleted sequence
  final String deleted;

  /// Start position of inserted sequence (after deletion)
  final int insertedAt;

  /// Inserted sequence
  final String inserted;

  Change({
    required this.type,
    required this.deletedAt,
    required this.deleted,
    required this.insertedAt,
    required this.inserted,
  });

  @override
  String toString() {
    return 'Change(type: $type, deletedAt: $deletedAt, deleted: "$deleted", insertedAt: $insertedAt, inserted: "$inserted")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Change) return false;
    return type == other.type &&
        deletedAt == other.deletedAt &&
        deleted == other.deleted &&
        insertedAt == other.insertedAt &&
        inserted == other.inserted;
  }

  @override
  int get hashCode {
    return type.hashCode ^ deletedAt.hashCode ^ deleted.hashCode ^ insertedAt.hashCode ^ inserted.hashCode;
  }
}
