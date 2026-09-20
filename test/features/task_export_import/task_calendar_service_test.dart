import 'package:flutter_test/flutter_test.dart';
import 'package:pin/entities/task/model/atomic_step.dart';
import 'package:pin/entities/task/model/pin_task.dart';
import 'package:pin/features/task_export_import/services/task_calendar_service.dart';

void main() {
  group('TaskCalendarService', () {
    final sampleTask = PinTask(
      id: 'task_cal_1',
      title: 'Architect sprint planning',
      description: 'Review roadmap & milestones',
      status: TaskStatus.today,
      energyTag: 'deep-focus',
      estimatedMinutes: 60,
      tags: ['#planning', '#leadership'],
      subtasks: const [
        AtomicStep(id: 's1', title: 'Prepare slides', isCompleted: true),
      ],
      createdAt: DateTime(2026, 9, 20, 9, 0),
      updatedAt: DateTime(2026, 9, 20, 9, 0),
    );

    test('generateSingleTaskIcs creates valid RFC 5545 VCALENDAR and VEVENT', () {
      final fixedStart = DateTime.utc(2026, 9, 21, 14, 0);
      final ics = TaskCalendarService.generateSingleTaskIcs(
        sampleTask,
        startTime: fixedStart,
      );

      expect(ics, contains('BEGIN:VCALENDAR'));
      expect(ics, contains('VERSION:2.0'));
      expect(ics, contains('BEGIN:VEVENT'));
      expect(ics, contains('SUMMARY:Architect sprint planning'));
      expect(ics, contains('DTSTART:20260921T140000Z'));
      expect(ics, contains('DTEND:20260921T150000Z'));
      expect(ics, contains('DESCRIPTION:Review roadmap & milestones'));
      expect(ics, contains('END:VEVENT'));
      expect(ics, contains('END:VCALENDAR'));
    });

    test('generateIcsCalendar exports multiple tasks sequentially', () {
      final fixedStart = DateTime.utc(2026, 9, 21, 10, 0);
      final task2 = sampleTask.copyWith(
        id: 'task_cal_2',
        title: 'Standup update',
        estimatedMinutes: 15,
      );

      final ics = TaskCalendarService.generateIcsCalendar(
        [sampleTask, task2],
        defaultStartDate: fixedStart,
      );

      expect(ics, contains('SUMMARY:Architect sprint planning'));
      expect(ics, contains('SUMMARY:Standup update'));
      expect(ics.indexOf('SUMMARY:Architect sprint planning'),
          lessThan(ics.indexOf('SUMMARY:Standup update')));
    });

    test('buildGoogleCalendarUrl creates correct URL structure', () {
      final fixedStart = DateTime.utc(2026, 9, 21, 16, 0);
      final url = TaskCalendarService.buildGoogleCalendarUrl(
        sampleTask,
        startTime: fixedStart,
      );

      expect(url.host, 'calendar.google.com');
      expect(url.path, '/calendar/render');
      expect(url.queryParameters['action'], 'TEMPLATE');
      expect(url.queryParameters['text'], 'Architect sprint planning');
      expect(url.queryParameters['dates'], '20260921T160000Z/20260921T170000Z');
      expect(url.queryParameters['details'], contains('Review roadmap & milestones'));
    });
  });
}
