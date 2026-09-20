import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/task_calendar_service.dart';

/// Tab for scheduling and exporting a single [PinTask] to calendar apps.
class SingleTaskCalendarTab extends StatefulWidget {
  final PinTask task;

  const SingleTaskCalendarTab({super.key, required this.task});

  @override
  State<SingleTaskCalendarTab> createState() => _SingleTaskCalendarTabState();
}

class _SingleTaskCalendarTabState extends State<SingleTaskCalendarTab> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _icsCopied = false;
  bool _isOpeningCalendar = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _selectedTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
  }

  DateTime get _eventDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _handleCopyIcs(String icsContent) async {
    await Clipboard.setData(ClipboardData(text: icsContent));
    setState(() => _icsCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _icsCopied = false);
    });
  }

  Future<void> _handleOpenCalendar() async {
    setState(() => _isOpeningCalendar = true);
    try {
      await TaskCalendarService.openInCalendar(
        widget.task,
        startTime: _eventDateTime,
      );
    } finally {
      if (mounted) setState(() => _isOpeningCalendar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    final icsContent = TaskCalendarService.generateSingleTaskIcs(
      widget.task,
      startTime: _eventDateTime,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: PinTokens.radiusMd,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: PinTokens.accentEmerald),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                borderRadius: PinTokens.radiusMd,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
                    borderRadius: PinTokens.radiusMd,
                    border: Border.all(
                      color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 15, color: PinTokens.accentEmerald),
                      const SizedBox(width: 6),
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(
                color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event: ${widget.task.title}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${widget.task.estimatedMinutes}m • ${widget.task.energyDisplayLabel}',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                const Spacer(),
                Text(
                  'Add to Google Calendar or system calendar app directly, or copy the standard RFC 5545 .ics event format.',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton(
              icon: _icsCopied ? Icons.check_rounded : Icons.copy_rounded,
              text: _icsCopied ? 'Copied .ics!' : 'Copy .ics',
              onPressed: () => _handleCopyIcs(icsContent),
            ),
            const SizedBox(width: 8),
            PinButton.primary(
              icon: Icons.open_in_new_rounded,
              text: _isOpeningCalendar ? 'Opening...' : 'Open in Calendar',
              onPressed: _isOpeningCalendar ? null : _handleOpenCalendar,
            ),
          ],
        ),
      ],
    );
  }
}
