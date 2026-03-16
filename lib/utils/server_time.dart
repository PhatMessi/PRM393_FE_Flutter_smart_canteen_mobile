class ServerTime {
  ServerTime._();

  /// Parses a backend DateTime string.
  ///
  /// In this project the backend stores and works in UTC, but it may serialize
  /// timestamps without an explicit timezone suffix (e.g. "2026-03-16T06:58:00").
  /// Dart treats such strings as local time, causing a 7-hour drift in Vietnam.
  ///
  /// This helper treats strings WITHOUT offset as UTC by appending 'Z'.
  static DateTime parseUtc(dynamic raw, {DateTime? fallback}) {
    final fb = fallback ?? DateTime.now().toUtc();
    if (raw == null) return fb;

    final s = raw.toString().trim();
    if (s.isEmpty) return fb;

    // If it already has timezone info (Z or +hh:mm / -hh:mm), parse directly.
    final hasZone = s.endsWith('Z') || s.contains('+') || _hasNegativeOffset(s);
    final parsed = DateTime.tryParse(hasZone ? s : '${s}Z');
    return parsed?.toUtc() ?? fb;
  }

  static bool _hasNegativeOffset(String s) {
    // Rough check for an offset like -07:00 at the end.
    final idx = s.lastIndexOf('-');
    if (idx <= 0) return false;
    final tail = s.substring(idx);
    return RegExp(r'^-\d{2}:\d{2}$').hasMatch(tail);
  }
}
