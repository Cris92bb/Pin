import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../entities/task/model/pin_task.dart';
import '../../../../entities/task/state/task_state_notifier.dart';
import '../../../../shared/ui/pin_button.dart';
import '../../../../shared/ui/pin_tokens.dart';
import '../../services/task_calendar_service.dart';

/// Tab for scheduling and exporting Pin tasks to system and web calendar applications.
class ExportCalendarTab extends ConsumerStatefulWidget {
  const ExportCalendarTab({super.key});

  @override
  ConsumerState<ExportCalendarTab> createState() => _ExportCalendarTabState();
}

class _ExportCalendarTabState extends ConsumerState<ExportCalendarTab> {
  String? _selectedTaskId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(hour: (DateTime.now().hour + 1) % 24, minute: 0);
  bool _copied = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final tasks = ref.read(taskStateProvider).tasks;
    if (tasks.isNotEmpty) {
      // Prefer today's tasks first
      final todayTask = tasks.where((t) => t.status == TaskStatus.today).firstOrNull;
      _selectedTaskId = todayTask?.id ?? tasks.first.id;
    }
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _handleAddToCalendar(PinTask task) async {
    setState(() => _isExporting = true);
    try {
      await TaskCalendarService.openInCalendar(task, startTime: _combinedDateTime);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleCopyIcs(PinTask task) async {
    final ics = TaskCalendarService.generateSingleTaskIcs(task, startTime: _combinedDateTime);
    await Clipboard.setData(ClipboardData(text: ics));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allTasks = ref.watch(taskStateProvider).tasks;

    final selectedTask = allTasks.where((t) => t.id == _selectedTaskId).firstOrNull ??
        (allTasks.isNotEmpty ? allTasks.first : null);

    final textPrimary = isDark ? PinTokens.darkTextPrimary : PinTokens.lightTextPrimary;
    final textSecondary = isDark ? PinTokens.darkTextSecondary : PinTokens.lightTextSecondary;

    if (allTasks.isEmpty) {
      return Center(
        child: Text(
          'No pins available to add to calendar.',
          style: TextStyle(color: textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Picker Dropdown
        Text(
          'Select Pin to Schedule:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
            borderRadius: PinTokens.radiusMd,
            border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTask?.id,
              isExpanded: true,
              dropdownColor: isDark ? PinTokens.darkCardBg : PinTokens.surfaceModal,
              icon: Icon(Icons.arrow_drop_down_rounded, color: textPrimary),
              items: allTasks.map((t) {
                return DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(
                    '${t.title} (${t.status.label}, ${t.estimatedMinutes}m)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: textPrimary),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedTaskId = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Date and Time Row
        Row(
          children: [
            Expanded(
              child: _buildPickerButton(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                onTap: _pickDate,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildPickerButton(
                icon: Icons.access_time_rounded,
                label: 'Start Time',
                value: _selectedTime.format(context),
                onTap: _pickTime,
                isDark: isDark,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Event Details Card Preview
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
              borderRadius: PinTokens.radiusMd,
              border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded, size: 16, color: PinTokens.accentEmerald),
                      const SizedBox(width: 6),
                      Text(
                        'Calendar Event Preview',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedTask?.title ?? 'No task selected',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${selectedTask?.estimatedMinutes ?? 15} minutes',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  if (selectedTask?.description.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      selectedTask!.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '💡 "Add to Calendar" opens Google Calendar or your default system calendar app directly.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PinButton(
              icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
              text: _copied ? 'Copied .ics!' : 'Copy .ics Data',
              onPressed: selectedTask != null ? () => _handleCopyIcs(selectedTask) : null,
            ),
            const SizedBox(width: 8),
            PinButton.primary(
              icon: Icons.open_in_new_rounded,
              text: _isExporting ? 'Opening...' : 'Add to Calendar',
              onPressed: (selectedTask != null && !_isExporting)
                  ? () => _handleAddToCalendar(selectedTask)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return InkWell(
      borderRadius: PinTokens.radiusMd,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? PinTokens.darkCanvasBg : PinTokens.canvasBg,
          borderRadius: PinTokens.radiusMd,
          border: Border.all(color: isDark ? PinTokens.darkBorder : PinTokens.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: PinTokens.accentEmerald),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: textSecondary)),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
