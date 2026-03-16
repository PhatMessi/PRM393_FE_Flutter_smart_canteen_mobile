class VnTime {
  VnTime._();

  static const Duration offset = Duration(hours: 7);

  /// Current time in Vietnam (UTC+7) regardless of device timezone.
  static DateTime now() => DateTime.now().toUtc().add(offset);

  /// Convert a server DateTime to Vietnam time.
  ///
  /// Server times in this project should be treated as UTC.
  static DateTime toVn(DateTime dt) => dt.toUtc().add(offset);

  /// Create an UTC DateTime from Vietnam "wall clock" components.
  /// Example: VN 12:00 -> UTC 05:00.
  static DateTime utcFromVnWall(int year, int month, int day, int hour24, int minute) {
    return DateTime.utc(year, month, day, hour24, minute).subtract(offset);
  }
}
