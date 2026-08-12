import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../models/automation_rule.dart';
import '../../providers/alert_provider.dart';

enum AlertFilter { all, unread, critical, automation }

enum _AlertMenuAction { markRead, markUnread, dismiss }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    final availableEvents = alertProvider.alerts.toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

    final filteredEvents = _applyFilter(availableEvents);

    final unreadCount = availableEvents
        .where((event) => !_isRead(event))
        .length;

    final unreadCriticalCount = availableEvents
        .where(
          (event) =>
              !_isRead(event) &&
              event.displaySeverity == AutomationSeverity.critical,
        )
        .length;

    final unreadWarningCount = availableEvents
        .where(
          (event) =>
              !_isRead(event) &&
              event.displaySeverity == AutomationSeverity.warning,
        )
        .length;

    final groupedEvents = _groupEventsByDate(filteredEvents);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _AlertsHeader(
                      hasEvents: availableEvents.isNotEmpty,
                      unreadCount: unreadCount,
                      onMarkAllRead: availableEvents.isEmpty
                          ? null
                          : () {
                              _markAllAsRead(availableEvents);
                            },
                      onClearAll: availableEvents.isEmpty
                          ? null
                          : () {
                              _confirmClearAll(alertProvider);
                            },
                    ),

                    if (alertProvider.isLoading ||
                        alertProvider.error != null) ...[
                      const SizedBox(height: 18),
                      AsyncStatusCard(
                        isLoading: alertProvider.isLoading,
                        error: alertProvider.error,
                        loadingMessage: 'Loading recent alerts…',
                        errorTitle: 'Alerts could not be refreshed',
                        onRetry: alertProvider.start,
                      ),
                    ],

                    const SizedBox(height: 22),

                    _AlertsHero(
                      totalCount: availableEvents.length,
                      unreadCount: unreadCount,
                      criticalCount: unreadCriticalCount,
                      warningCount: unreadWarningCount,
                    ),

                    const SizedBox(height: 30),

                    const _SectionHeader(
                      title: 'Alert centre',
                      subtitle:
                          'Review safety, security and automation activity.',
                    ),

                    const SizedBox(height: 15),

                    _AlertFilterBar(
                      selectedFilter: _selectedFilter,
                      unreadCount: unreadCount,
                      onChanged: (filter) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    ),

                    const SizedBox(height: 22),

                    if (filteredEvents.isEmpty)
                      _EmptyAlertsCard(
                        filter: _selectedFilter,
                        hasAnyEvents: availableEvents.isNotEmpty,
                      )
                    else
                      ...groupedEvents.entries.expand((entry) {
                        return <Widget>[
                          _DateSectionHeader(
                            title: entry.key,
                            count: entry.value.length,
                          ),
                          const SizedBox(height: 11),
                          ...entry.value.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 13),
                              child: _AlertCard(
                                event: event,
                                isRead: _isRead(event),
                                onTap: () {
                                  _openAlertDetails(context, event);
                                },
                                onMenuAction: (action) {
                                  _handleMenuAction(event, action);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                        ];
                      }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AutomationEvent> _applyFilter(List<AutomationEvent> events) {
    switch (_selectedFilter) {
      case AlertFilter.all:
        return events;

      case AlertFilter.unread:
        return events.where((event) => !_isRead(event)).toList();

      case AlertFilter.critical:
        return events
            .where(
              (event) => event.displaySeverity == AutomationSeverity.critical,
            )
            .toList();

      case AlertFilter.automation:
        return events.where((event) => event.isAutomationCategory).toList();
    }
  }

  Map<String, List<AutomationEvent>> _groupEventsByDate(
    List<AutomationEvent> events,
  ) {
    final groups = <String, List<AutomationEvent>>{};

    for (final event in events) {
      final groupTitle = _dateGroupTitle(event.createdAt);

      groups.putIfAbsent(groupTitle, () => <AutomationEvent>[]).add(event);
    }

    return groups;
  }

  String _dateGroupTitle(DateTime timestamp) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final eventDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final difference = today.difference(eventDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (timestamp.year == now.year) {
      return DateFormat('d MMMM').format(timestamp);
    }

    return DateFormat('d MMMM yyyy').format(timestamp);
  }

  bool _isRead(AutomationEvent event) {
    return event.isRead;
  }

  void _markAllAsRead(List<AutomationEvent> events) {
    context.read<AlertProvider>().markAllRead();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All alerts marked as read.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmClearAll(AlertProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all alerts?'),
          content: const Text(
            'This will remove all current automation '
            'events from the alert centre.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await provider.clear();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All alerts cleared.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMenuAction(AutomationEvent event, _AlertMenuAction action) {
    switch (action) {
      case _AlertMenuAction.markRead:
        context.read<AlertProvider>().setRead(event.id, true);
        break;

      case _AlertMenuAction.markUnread:
        context.read<AlertProvider>().setRead(event.id, false);
        break;

      case _AlertMenuAction.dismiss:
        _confirmDeleteAlert(event);
        break;
    }
  }

  Future<void> _confirmDeleteAlert(AutomationEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text('${event.displayTitle} will be removed from Firebase.'),
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
    if (confirmed != true || !mounted) return;

    await context.read<AlertProvider>().delete(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAlertDetails(
    BuildContext context,
    AutomationEvent event,
  ) async {
    final alertProvider = context.read<AlertProvider>();
    await alertProvider.setRead(event.id, true);

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      builder: (sheetContext) {
        return _AlertDetailSheet(event: event);
      },
    );
  }
}

class _AlertsHeader extends StatelessWidget {
  const _AlertsHeader({
    required this.hasEvents,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final bool hasEvents;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alerts',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                unreadCount == 0
                    ? 'You are all caught up.'
                    : '$unreadCount unread '
                          '${unreadCount == 1 ? 'alert' : 'alerts'}.',
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          enabled: hasEvents,
          tooltip: 'Alert options',
          color: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onSelected: (value) {
            if (value == 'read') {
              onMarkAllRead?.call();
            } else if (value == 'clear') {
              onClearAll?.call();
            }
          },
          itemBuilder: (_) {
            return const [
              PopupMenuItem<String>(
                value: 'read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded),
                    SizedBox(width: 11),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    SizedBox(width: 11),
                    Text('Clear all'),
                  ],
                ),
              ),
            ];
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertsHero extends StatelessWidget {
  const _AlertsHero({
    required this.totalCount,
    required this.unreadCount,
    required this.criticalCount,
    required this.warningCount,
  });

  final int totalCount;
  final int unreadCount;
  final int criticalCount;
  final int warningCount;

  bool get _hasCritical => criticalCount > 0;

  bool get _hasWarning => !_hasCritical && warningCount > 0;

  @override
  Widget build(BuildContext context) {
    final gradientColors = _hasCritical
        ? const [Color(0xFF8F2020), Color(0xFFD84242), Color(0xFFF16A52)]
        : _hasWarning
        ? const [Color(0xFFB66D16), Color(0xFFE59A2F), Color(0xFFFFC857)]
        : const [Color(0xFF176B4A), Color(0xFF42A15A), Color(0xFF8BCD4C)];

    final title = _hasCritical
        ? 'Immediate attention required.'
        : _hasWarning
        ? 'Please review recent activity.'
        : 'Your room is protected.';

    final subtitle = totalCount == 0
        ? 'Automation alerts will appear here.'
        : unreadCount == 0
        ? 'All recent alerts have been reviewed.'
        : '$unreadCount alert'
              '${unreadCount == 1 ? '' : 's'} '
              'waiting for your review.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -45,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _hasCritical
                        ? Icons.warning_amber_rounded
                        : _hasWarning
                        ? Icons.notifications_active_rounded
                        : Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SMART ALERT CENTRE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 23),
              Row(
                children: [
                  Expanded(
                    child: _AlertHeroStat(
                      value: '$unreadCount',
                      label: 'Unread',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AlertHeroStat(
                      value: '$criticalCount',
                      label: 'Critical',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AlertHeroStat(
                      value: '$warningCount',
                      label: 'Warnings',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertHeroStat extends StatelessWidget {
  const _AlertHeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertFilterBar extends StatelessWidget {
  const _AlertFilterBar({
    required this.selectedFilter,
    required this.unreadCount,
    required this.onChanged,
  });

  final AlertFilter selectedFilter;
  final int unreadCount;
  final ValueChanged<AlertFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = <AlertFilter>[
      AlertFilter.all,
      AlertFilter.unread,
      AlertFilter.critical,
      AlertFilter.automation,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final selected = filter == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _filterIcon(filter),
                    size: 17,
                    color: selected ? Colors.white : _filterColor(filter),
                  ),
                  const SizedBox(width: 7),
                  Text(_filterLabel(filter, unreadCount)),
                ],
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.lightText,
                fontWeight: FontWeight.w700,
              ),
              selectedColor: AppColors.primaryDark,
              backgroundColor: Colors.white.withValues(alpha: 0.75),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              onSelected: (_) {
                onChanged(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  static String _filterLabel(AlertFilter filter, int unreadCount) {
    switch (filter) {
      case AlertFilter.all:
        return 'All';

      case AlertFilter.unread:
        return unreadCount == 0 ? 'Unread' : 'Unread $unreadCount';

      case AlertFilter.critical:
        return 'Critical';

      case AlertFilter.automation:
        return 'Automation';
    }
  }

  static IconData _filterIcon(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
        return Icons.notifications_rounded;

      case AlertFilter.unread:
        return Icons.mark_email_unread_rounded;

      case AlertFilter.critical:
        return Icons.warning_rounded;

      case AlertFilter.automation:
        return Icons.auto_awesome_rounded;
    }
  }

  static Color _filterColor(AlertFilter filter) {
    switch (filter) {
      case AlertFilter.all:
      case AlertFilter.unread:
        return AppColors.primaryDark;

      case AlertFilter.critical:
        return AppColors.danger;

      case AlertFilter.automation:
        return AppColors.accentPurple;
    }
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.event,
    required this.isRead,
    required this.onTap,
    required this.onMenuAction,
  });

  final AutomationEvent event;
  final bool isRead;
  final VoidCallback onTap;
  final ValueChanged<_AlertMenuAction> onMenuAction;

  @override
  Widget build(BuildContext context) {
    final accent = _severityColor(event.displaySeverity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white.withValues(alpha: 0.69)
                : Colors.white.withValues(alpha: 0.91),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: isRead
                  ? Colors.white.withValues(alpha: 0.8)
                  : accent.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: isRead
                    ? Colors.black.withValues(alpha: 0.025)
                    : accent.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 11),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_eventIcon(event), color: accent, size: 26),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _severityLabel(event.displaySeverity),
                            style: TextStyle(
                              color: accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),

                        if (event.isTest) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'TEST',
                              style: TextStyle(
                                color: AppColors.accentPurple,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.55,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        Text(
                          DateFormat('h:mm a').format(event.createdAt),
                          style: const TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 3),

                        PopupMenuButton<_AlertMenuAction>(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          tooltip: 'Alert options',
                          onSelected: onMenuAction,
                          itemBuilder: (_) {
                            return [
                              PopupMenuItem<_AlertMenuAction>(
                                value: isRead
                                    ? _AlertMenuAction.markUnread
                                    : _AlertMenuAction.markRead,
                                child: Row(
                                  children: [
                                    Icon(
                                      isRead
                                          ? Icons.mark_email_unread_outlined
                                          : Icons.done_rounded,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(isRead ? 'Mark unread' : 'Mark read'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<_AlertMenuAction>(
                                value: _AlertMenuAction.dismiss,
                                child: Row(
                                  children: [
                                    Icon(Icons.close_rounded),
                                    SizedBox(width: 10),
                                    Text('Dismiss'),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 11),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w700
                                      : FontWeight.w800,
                                ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      event.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 11),

                    Row(
                      children: [
                        Icon(
                          _categoryIcon(event.ruleId),
                          color: AppColors.lightTextSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.category,
                          style: const TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'View details',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryDark,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertDetailSheet extends StatelessWidget {
  const _AlertDetailSheet({required this.event});

  final AutomationEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = _severityColor(event.displaySeverity);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_eventIcon(event), color: accent, size: 29),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _severityLabel(event.displaySeverity),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.displayTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _DetailInformationCard(
              icon: Icons.schedule_rounded,
              title: 'Detected',
              value: DateFormat(
                'd MMMM yyyy • h:mm:ss a',
              ).format(event.createdAt),
            ),

            const SizedBox(height: 11),

            _DetailInformationCard(
              icon: _categoryIcon(event.ruleId),
              title: 'Category',
              value: event.category,
            ),

            const SizedBox(height: 11),

            _DetailInformationCard(
              icon: Icons.sensors_rounded,
              title: 'Trigger',
              value: event.triggerDescription,
            ),

            const SizedBox(height: 25),

            const Text(
              'What happened',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                event.message,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  height: 1.55,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Automatic actions',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 11),

            if (event.automaticActions.isEmpty)
              const _NoActionsCard()
            else
              ...event.automaticActions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _AutomaticActionRow(action: action),
                ),
              ),

            if (event.isTest) ...[
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(21),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.science_rounded, color: AppColors.accentPurple),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'This alert was produced by a '
                        'manual automation test. No real '
                        'sensor emergency was detected.',
                        style: TextStyle(
                          color: AppColors.lightTextSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInformationCard extends StatelessWidget {
  const _DetailInformationCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomaticActionRow extends StatelessWidget {
  const _AutomaticActionRow({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: AppColors.safe.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.safe,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoActionsCard extends StatelessWidget {
  const _NoActionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryDark),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'No automatic actions were recorded '
              'for this event.',
              style: TextStyle(color: AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.50),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAlertsCard extends StatelessWidget {
  const _EmptyAlertsCard({required this.filter, required this.hasAnyEvents});

  final AlertFilter filter;
  final bool hasAnyEvents;

  @override
  Widget build(BuildContext context) {
    final isFilteredEmpty = hasAnyEvents && filter != AlertFilter.all;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.50),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFilteredEmpty
                  ? Icons.filter_alt_off_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.primaryDark,
              size: 39,
            ),
          ),
          const SizedBox(height: 19),
          Text(
            filter == AlertFilter.unread && isFilteredEmpty
                ? 'No unread alerts'
                : isFilteredEmpty
                ? 'No matching alerts'
                : 'No alerts yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            isFilteredEmpty
                ? filter == AlertFilter.unread
                      ? "You're all caught up."
                      : 'Try another filter to review your room activity.'
                : 'Your room is operating normally.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

Color _severityColor(AutomationSeverity severity) {
  switch (severity) {
    case AutomationSeverity.info:
      return AppColors.accentBlue;

    case AutomationSeverity.warning:
      return AppColors.warning;

    case AutomationSeverity.critical:
      return AppColors.danger;
  }
}

String _severityLabel(AutomationSeverity severity) {
  switch (severity) {
    case AutomationSeverity.info:
      return 'INFORMATION';

    case AutomationSeverity.warning:
      return 'WARNING';

    case AutomationSeverity.critical:
      return 'CRITICAL';
  }
}

IconData _eventIcon(AutomationEvent event) {
  if (event.isTest) {
    return Icons.science_rounded;
  }

  switch (event.ruleId) {
    case 'temperatureFan':
      return Icons.thermostat_rounded;

    case 'lowLight':
      return Icons.lightbulb_rounded;

    case 'motionSecurity':
      return Icons.security_rounded;

    case 'rainCurtain':
      return Icons.water_drop_rounded;

    case 'gasEmergency':
      return Icons.warning_amber_rounded;

    default:
      return Icons.notifications_rounded;
  }
}

IconData _categoryIcon(String ruleId) {
  switch (ruleId) {
    case 'temperatureFan':
      return Icons.device_thermostat_rounded;

    case 'lowLight':
      return Icons.light_mode_rounded;

    case 'motionSecurity':
      return Icons.shield_rounded;

    case 'rainCurtain':
      return Icons.cloud_rounded;

    case 'gasEmergency':
      return Icons.emergency_rounded;

    default:
      return Icons.settings_rounded;
  }
}
