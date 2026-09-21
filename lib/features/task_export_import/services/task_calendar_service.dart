import 'package:url_launcher/url_launcher.dart';
import '../../../entities/task/model/pin_task.dart';

/// Service for generating RFC 5545 iCalendar (`.ics`) data and opening calendar events.
///
/// Enables seamless addition of Pin tasks to Google Calendar, Apple Calendar,
/// Outlook, Thunderbird, and native mobile calendar apps via intent URLs or `.ics` export.
class TaskCalendarService {
  /// Generates a complete RFC 5545 `.ics` iCalendar document containing the given [tasks].
  static String generateIcsCalendar(
    List<PinTask> tasks, {
    DateTime? defaultStartDate,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Pin App//Kanban//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    final now = DateTime.now().toUtc();
    var offsetMinutes = 0;

    for (final task in tasks) {
      final start = (defaultStartDate ?? _inferTaskStartDate(task))
          .toUtc()
          .add(Duration(minutes: offsetMinutes));
      final duration = Duration(minutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 30);
      final end = start.add(duration);

      _writeVEvent(buffer, task, now, start, end);
      offsetMinutes += duration.inMinutes + 15; // Gap between tasks
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  /// Generates a single RFC 5545 `.ics` VCALENDAR for an individual [PinTask].
  static String generateSingleTaskIcs(
    PinTask task, {
    DateTime? startTime,
    Duration? duration,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Pin App//Kanban//EN');
    buffer.writeln('CALSCALE:GREGORIAN');
    buffer.writeln('METHOD:PUBLISH');

    final now = DateTime.now().toUtc();
    final start = (startTime ?? _inferTaskStartDate(task)).toUtc();
    final eventDuration = duration ?? Duration(minutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 30);
    final end = start.add(eventDuration);

    _writeVEvent(buffer, task, now, start, end);

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static void _writeVEvent(
    StringBuffer buffer,
    PinTask task,
    DateTime nowUtc,
    DateTime startUtc,
    DateTime endUtc,
  ) {
    buffer.writeln('BEGIN:VEVENT');
    buffer.writeln('UID:pin_${task.id}_${startUtc.millisecondsSinceEpoch}@pin.app');
    buffer.writeln('DTSTAMP:${_formatIcsDate(nowUtc)}');
    buffer.writeln('DTSTART:${_formatIcsDate(startUtc)}');
    buffer.writeln('DTEND:${_formatIcsDate(endUtc)}');
    buffer.writeln('SUMMARY:${_escapeIcsText(task.title)}');

    final desc = _buildEventDescription(task);
    if (desc.isNotEmpty) {
      buffer.writeln('DESCRIPTION:${_escapeIcsText(desc)}');
    }

    buffer.writeln('STATUS:CONFIRMED');
    buffer.writeln('TRANSP:OPAQUE');
    buffer.writeln('END:VEVENT');
  }

  /// Builds a Google Calendar web/app template URL for instant event creation.
  static Uri buildGoogleCalendarUrl(
    PinTask task, {
    DateTime? startTime,
    Duration? duration,
  }) {
    final start = (startTime ?? _inferTaskStartDate(task)).toUtc();
    final eventDuration = duration ?? Duration(minutes: task.estimatedMinutes > 0 ? task.estimatedMinutes : 30);
    final end = start.add(eventDuration);

    final startStr = _formatIcsDate(start);
    final endStr = _formatIcsDate(end);
    final datesParam = '$startStr/$endStr';

    final details = _buildEventDescription(task);

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': task.title,
      'details': details,
      'dates': datesParam,
    });
  }

  /// Launches the system or Google Calendar event editor for the specified [task].
  static Future<bool> openInCalendar(
    PinTask task, {
    DateTime? startTime,
    Duration? duration,
  }) async {
    final uri = buildGoogleCalendarUrl(task, startTime: startTime, duration: duration);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static DateTime _inferTaskStartDate(PinTask task) {
    if (task.scheduledFor != null) {
      final parsed = DateTime.tryParse(task.scheduledFor!);
      if (parsed != null) return parsed;
    }
    // Default to the next nearest hour
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1, 0);
  }

  static String _buildEventDescription(PinTask task) {
    final parts = <String>[];
    if (task.description.trim().isNotEmpty) {
      parts.add(task.description.trim());
    }
    final meta = <String>[];
    meta.add('Category: ${task.category}');
    meta.add('Energy: ${task.energyDisplayLabel}');
    if (task.tags.isNotEmpty) {
      meta.add('Tags: ${task.tags.join(', ')}');
    }
    parts.add(meta.join(' | '));

    if (task.subtasks.isNotEmpty) {
      parts.add('Subtasks:');
      for (final step in task.subtasks) {
        final mark = step.isCompleted ? '[x]' : '[ ]';
        parts.add('$mark ${step.title}');
      }
    }
    return parts.join('\n');
  }

  static String _formatIcsDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  static String _escapeIcsText(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }
}
