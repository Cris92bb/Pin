/// Helpers for formatting durations and timestamps in Pin.
class DateHelpers {
  const DateHelpers._();

  /// Formats seconds into mm:ss or hh:mm:ss
  static String formatSeconds(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  /// Formats minutes into human-readable representation like "~15m", "~1h 30m"
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    if (minutes < 60) return '~${minutes}m';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (remainder == 0) return '~${hours}h';
    return '~${hours}h ${remainder}m';
  }

  /// Formats a DateTime into a friendly relative string
  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return '$h hr${h == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final d = difference.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}
