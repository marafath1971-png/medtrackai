/// Safely parses date/time from diverse sources (ISO-8601 strings,
/// Firestore Timestamps with `.toDate()`, millisecondsSinceEpoch, etc.)
/// without throwing FormatException or TypeError.
DateTime? tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  // Handle Firestore Timestamp or similar classes duck-typed with `.toDate()`
  try {
    final dynamic dynamicVal = value;
    if (dynamicVal.toDate != null) {
      final res = dynamicVal.toDate();
      if (res is DateTime) return res;
    }
  } catch (_) {}

  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return null;
    }
  }

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  return null;
}
