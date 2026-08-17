import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../models/device_schedule.dart';
import '../../models/smart_device.dart';
import '../../providers/device_provider.dart';
import '../../providers/schedule_provider.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({this.initialDeviceId, super.key});

  final String? initialDeviceId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final schedules = initialDeviceId == null
        ? provider.schedules
        : provider.forDevice(initialDeviceId!);
    final upcoming =
        schedules
            .where((schedule) => schedule.enabled)
            .map((schedule) => (schedule, schedule.nextOccurrence()))
            .where((item) => item.$2 != null)
            .toList()
          ..sort((a, b) => a.$2!.compareTo(b.$2!));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, deviceId: initialDeviceId),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New schedule',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              Color(0xFFEAF3DD),
              Color(0xFFF7EFDF),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        _RoundButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedules',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                              ),
                              Text(
                                initialDeviceId == null
                                    ? 'Timed actions for your smart room.'
                                    : 'Timed actions for this device.',
                                style: const TextStyle(
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (provider.isLoading || provider.error != null) ...[
                      const SizedBox(height: 18),
                      AsyncStatusCard(
                        isLoading: provider.isLoading,
                        error: provider.error,
                        loadingMessage: 'Loading schedules…',
                        errorTitle: 'Schedules could not be refreshed',
                        onRetry: provider.start,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _UpcomingCard(
                      schedule: upcoming.isEmpty ? null : upcoming.first.$1,
                      occurrence: upcoming.isEmpty ? null : upcoming.first.$2,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'All schedules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (schedules.isEmpty)
                      const _EmptySchedules()
                    else
                      ...schedules.map(
                        (schedule) => Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: _ScheduleCard(
                            schedule: schedule,
                            onToggle: (enabled) {
                              provider.setEnabled(schedule, enabled);
                            },
                            onEdit: () =>
                                _openEditor(context, schedule: schedule),
                            onDelete: () => _confirmDelete(context, schedule),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _openEditor(
    BuildContext context, {
    String? deviceId,
    DeviceSchedule? schedule,
  }) {
    final deviceProvider = context.read<DeviceProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
          ChangeNotifierProvider<ScheduleProvider>.value(
            value: scheduleProvider,
          ),
        ],
        child: _ScheduleEditor(initialDeviceId: deviceId, schedule: schedule),
      ),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    DeviceSchedule schedule,
  ) async {
    final provider = context.read<ScheduleProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text(
          'The scheduled action for ${schedule.deviceName} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.delete(schedule.id);
    }
  }
}

class _ScheduleEditor extends StatefulWidget {
  const _ScheduleEditor({this.initialDeviceId, this.schedule});

  final String? initialDeviceId;
  final DeviceSchedule? schedule;

  @override
  State<_ScheduleEditor> createState() => _ScheduleEditorState();
}

class _ScheduleEditorState extends State<_ScheduleEditor> {
  late final TextEditingController _nameController;
  late String? _deviceId;
  late bool _turnOn;
  late TimeOfDay _time;
  late Set<int> _weekdays;
  late int _level;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    _nameController = TextEditingController(text: schedule?.name ?? '');
    _deviceId = schedule?.deviceId ?? widget.initialDeviceId;
    _turnOn = schedule?.turnOn ?? true;
    _time = TimeOfDay(
      hour: schedule?.hour ?? TimeOfDay.now().hour,
      minute: schedule?.minute ?? TimeOfDay.now().minute,
    );
    _weekdays = {...?schedule?.weekdays};
    _level = schedule?.level ?? 70;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final deviceId = _deviceId;
    if (deviceId == null || _saving) return;
    final devices = context.read<DeviceProvider>();
    final schedules = context.read<ScheduleProvider>();
    final device = devices.byId(deviceId);
    if (device == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final supportsLevel =
        device.type == DeviceType.whiteLight || device.type == DeviceType.fan;

    setState(() => _saving = true);
    if (widget.schedule == null) {
      await schedules.create(
        name: name,
        deviceId: device.id,
        deviceName: device.name,
        turnOn: _turnOn,
        hour: _time.hour,
        minute: _time.minute,
        weekdays: _weekdays.toList(),
        level: supportsLevel && _turnOn ? _level : null,
      );
    } else {
      await schedules.update(
        widget.schedule!.copyWith(
          name: name,
          deviceId: device.id,
          deviceName: device.name,
          turnOn: _turnOn,
          hour: _time.hour,
          minute: _time.minute,
          weekdays: _weekdays.toList()..sort(),
          enabled: true,
          level: supportsLevel && _turnOn ? _level : null,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _selectTimeWithClock() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.dialOnly,
    );

    if (value != null && mounted) {
      setState(() => _time = value);
    }
  }

  Future<void> _enterTimeWithKeyboard() async {
    final value = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _KeyboardTimeDialog(initialTime: _time),
    );

    if (value != null && mounted) {
      setState(() => _time = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<DeviceProvider>().devices;
    SmartDevice? selected;
    for (final device in devices) {
      if (device.id == _deviceId) selected = device;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          6,
          22,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.schedule == null ? 'Create schedule' : 'Edit schedule',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose a device, action, time and repeat pattern.',
              style: TextStyle(color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Schedule name',
                hintText: 'Example: Morning Curtain',
                prefixIcon: Icon(Icons.edit_calendar_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _deviceId,
              decoration: const InputDecoration(
                labelText: 'Device',
                prefixIcon: Icon(Icons.devices_other_rounded),
              ),
              items: devices
                  .map(
                    (device) => DropdownMenuItem(
                      value: device.id,
                      child: Text(device.name),
                    ),
                  )
                  .toList(),
              onChanged: widget.initialDeviceId == null
                  ? (value) => setState(() {
                      _deviceId = value;
                      _turnOn = true;
                    })
                  : null,
            ),
            if (_turnOn &&
                (selected?.type == DeviceType.whiteLight ||
                    selected?.type == DeviceType.fan)) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selected?.type == DeviceType.fan
                          ? 'Fan speed'
                          : 'Brightness',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '$_level%',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _level.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                label: '$_level%',
                onChanged: (value) => setState(() => _level = value.round()),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  label: Text(_positiveLabel(selected?.type)),
                  icon: const Icon(Icons.power_settings_new_rounded),
                ),
                ButtonSegment(
                  value: false,
                  label: Text(_negativeLabel(selected?.type)),
                  icon: const Icon(Icons.power_off_rounded),
                ),
              ],
              selected: {_turnOn},
              onSelectionChanged: (value) {
                setState(() => _turnOn = value.first);
              },
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: const Icon(
                Icons.schedule_rounded,
                color: AppColors.primaryDark,
              ),
              title: const Text(
                'Action time',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(_time.format(context)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Enter time with keyboard',
                    onPressed: _enterTimeWithKeyboard,
                    icon: const Icon(
                      Icons.keyboard_alt_outlined,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: _selectTimeWithClock,
            ),
            const SizedBox(height: 13),
            const Text(
              'Repeat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Leave all days unselected for a one-time action.',
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _RepeatPresetChip(
                  label: 'Once',
                  selected: _weekdays.isEmpty,
                  onTap: () => setState(_weekdays.clear),
                ),
                _RepeatPresetChip(
                  label: 'Every day',
                  selected: _weekdays.length == 7,
                  onTap: () =>
                      setState(() => _weekdays = {1, 2, 3, 4, 5, 6, 7}),
                ),
                _RepeatPresetChip(
                  label: 'Weekdays',
                  selected: _sameDays(_weekdays, {1, 2, 3, 4, 5}),
                  onTap: () => setState(() => _weekdays = {1, 2, 3, 4, 5}),
                ),
                _RepeatPresetChip(
                  label: 'Weekends',
                  selected: _sameDays(_weekdays, {6, 7}),
                  onTap: () => setState(() => _weekdays = {6, 7}),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]),
                  selected: _weekdays.contains(day),
                  onSelected: (isSelected) {
                    setState(() {
                      isSelected ? _weekdays.add(day) : _weekdays.remove(day);
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed:
                    _deviceId == null ||
                        _nameController.text.trim().isEmpty ||
                        _saving
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.schedule == null
                            ? 'Create schedule'
                            : 'Save changes',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardTimeDialog extends StatefulWidget {
  const _KeyboardTimeDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_KeyboardTimeDialog> createState() => _KeyboardTimeDialogState();
}

class _KeyboardTimeDialogState extends State<_KeyboardTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourController;
  late final TextEditingController _minuteController;
  late bool _isPm;

  @override
  void initState() {
    super.initState();
    final hour = widget.initialTime.hourOfPeriod == 0
        ? 12
        : widget.initialTime.hourOfPeriod;
    _hourController = TextEditingController(text: hour.toString());
    _minuteController = TextEditingController(
      text: widget.initialTime.minute.toString().padLeft(2, '0'),
    );
    _isPm = widget.initialTime.period == DayPeriod.pm;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final enteredHour = int.parse(_hourController.text);
    final minute = int.parse(_minuteController.text);
    final hour = (enteredHour % 12) + (_isPm ? 12 : 0);

    Navigator.pop(context, TimeOfDay(hour: hour, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: AppColors.lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.keyboard_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter action time',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Use the numeric keyboard',
                          style: TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeNumberField(
                      controller: _hourController,
                      label: 'Hour',
                      hint: '1–12',
                      maximum: 12,
                      minimum: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 17, 10, 0),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TimeNumberField(
                      controller: _minuteController,
                      label: 'Minute',
                      hint: '0–59',
                      maximum: 59,
                      minimum: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('AM')),
                    ButtonSegment(value: true, label: Text('PM')),
                  ],
                  selected: {_isPm},
                  onSelectionChanged: (value) {
                    setState(() {
                      _isPm = value.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Set time',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeNumberField extends StatelessWidget {
  const _TimeNumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.minimum,
    required this.maximum,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int minimum;
  final int maximum;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: label == 'Hour'
          ? TextInputAction.next
          : TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null || number < minimum || number > maximum) {
          return '$minimum–$maximum';
        }
        return null;
      },
      onFieldSubmitted: (_) {
        if (label == 'Minute') {
          FocusScope.of(context).unfocus();
        }
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({this.schedule, this.occurrence});
  final DeviceSchedule? schedule;
  final DateTime? occurrence;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF176B4A), Color(0xFF75B83B)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: schedule == null
          ? const Text(
              'No upcoming scheduled actions.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UPCOMING ACTION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  schedule!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${schedule!.actionLabel} ${schedule!.deviceName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('EEE, d MMM • h:mm a').format(occurrence!),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final DeviceSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Row(
        children: [
          Container(
            width: 53,
            height: 53,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${schedule.actionLabel} ${schedule.deviceName} • '
                    '${TimeOfDay(hour: schedule.hour, minute: schedule.minute).format(context)}',
                    style: const TextStyle(color: AppColors.lightTextSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _repeatLabel(schedule.weekdays),
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Switch.adaptive(value: schedule.enabled, onChanged: onToggle),
              IconButton(
                tooltip: 'Delete schedule',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepeatPresetChip extends StatelessWidget {
  const _RepeatPresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 45,
            color: AppColors.primaryDark,
          ),
          SizedBox(height: 13),
          Text(
            'No schedules yet',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Create a timed device action using the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(width: 48, height: 48, child: Icon(icon)),
      ),
    );
  }
}

String _repeatLabel(List<int> weekdays) {
  if (weekdays.isEmpty) return 'Once';
  if (weekdays.length == 7) return 'Every day';
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays.map((day) => names[day - 1]).join(', ');
}

bool _sameDays(Set<int> first, Set<int> second) {
  return first.length == second.length && first.containsAll(second);
}

String _positiveLabel(DeviceType? type) => switch (type) {
  DeviceType.curtain => 'Open',
  DeviceType.doorLock => 'Lock',
  _ => 'Turn ON',
};

String _negativeLabel(DeviceType? type) => switch (type) {
  DeviceType.curtain => 'Close',
  DeviceType.doorLock => 'Unlock',
  _ => 'Turn OFF',
};
