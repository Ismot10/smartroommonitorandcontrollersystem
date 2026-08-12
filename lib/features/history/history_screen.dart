import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../models/automation_rule.dart';
import '../../models/history_record.dart';
import '../../providers/automation_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/history_provider.dart';

import 'dart:math' as math;

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    final automation = context.watch<AutomationProvider>();

    final devices = context.watch<DeviceProvider>();

    final records = history.filteredRecords;

    final activeDeviceCount = devices.devices
        .where((device) => device.isOn)
        .length;

    final physicalDeviceCount = devices.devices
        .where((device) => device.isPhysical)
        .length;

    final criticalAlerts = automation.events
        .where((event) => event.severity == AutomationSeverity.critical)
        .length;

    final warningAlerts = automation.events
        .where((event) => event.severity == AutomationSeverity.warning)
        .length;

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 35),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _HistoryHeader(),

                    if (history.isLoading || history.error != null) ...[
                      const SizedBox(height: 18),
                      AsyncStatusCard(
                        isLoading: history.isLoading,
                        error: history.error,
                        loadingMessage: 'Loading room analytics…',
                        errorTitle: 'History could not be refreshed',
                        onRetry: history.start,
                      ),
                    ],

                    const SizedBox(height: 22),

                    _AnalyticsHero(
                      recordCount: records.length,
                      alertCount: automation.events.length,
                      activeDeviceCount: activeDeviceCount,
                      motionCount: history.motionEventCount,
                    ),

                    const SizedBox(height: 28),

                    _RangeSelector(
                      selected: history.selectedRange,
                      onSelected: history.setRange,
                    ),

                    const SizedBox(height: 26),

                    const _SectionHeader(
                      title: 'Environment trends',
                      subtitle:
                          'Explore changes recorded by your smart-room sensors.',
                    ),

                    const SizedBox(height: 15),

                    _MetricSelector(
                      selected: history.selectedMetric,
                      onSelected: history.setMetric,
                    ),

                    const SizedBox(height: 15),

                    _SensorChartCard(history: history, records: records),

                    const SizedBox(height: 16),

                    _StatisticsGrid(history: history),

                    const SizedBox(height: 30),

                    const _SectionHeader(
                      title: 'Activity overview',
                      subtitle:
                          'A summary of devices, alerts and environmental events.',
                    ),

                    const SizedBox(height: 15),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      childAspectRatio: 1.08,
                      children: [
                        _ActivityCard(
                          icon: Icons.devices_other_rounded,
                          accent: AppColors.primaryDark,
                          value: '$activeDeviceCount',
                          title: 'Active devices',
                          subtitle: '$physicalDeviceCount physical',
                        ),
                        _ActivityCard(
                          icon: Icons.warning_amber_rounded,
                          accent: AppColors.danger,
                          value: '$criticalAlerts',
                          title: 'Critical alerts',
                          subtitle: '$warningAlerts warnings',
                        ),
                        _ActivityCard(
                          icon: Icons.directions_walk_rounded,
                          accent: AppColors.motion,
                          value: '${history.motionEventCount}',
                          title: 'Motion records',
                          subtitle: _rangeLabel(history.selectedRange),
                        ),
                        _ActivityCard(
                          icon: Icons.water_drop_rounded,
                          accent: AppColors.rain,
                          value: '${history.rainEventCount}',
                          title: 'Rain records',
                          subtitle: _rangeLabel(history.selectedRange),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        const Expanded(
                          child: _SectionHeader(
                            title: 'Automation timeline',
                            subtitle:
                                'Recent decisions and actions taken by Aurora.',
                          ),
                        ),
                        if (automation.events.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${automation.events.length}',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (automation.events.isEmpty)
                      const _EmptyTimeline()
                    else
                      ...automation.events
                          .take(6)
                          .map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _TimelineEventCard(event: event),
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

  static String _rangeLabel(HistoryRange range) {
    return switch (range) {
      HistoryRange.hour => 'During the last hour',
      HistoryRange.day => 'During the last day',
      HistoryRange.week => 'During the last week',
    };
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.pop(context);
            },
            child: const SizedBox(
              width: 49,
              height: 49,
              child: Icon(Icons.arrow_back_rounded),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'History & Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Insights from your smart room.',
                style: TextStyle(color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.recordCount,
    required this.alertCount,
    required this.activeDeviceCount,
    required this.motionCount,
  });

  final int recordCount;
  final int alertCount;
  final int activeDeviceCount;
  final int motionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4934A7), Color(0xFF7656E8), Color(0xFFA983F4)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPurple.withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 17),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -55,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.white),
                  SizedBox(width: 9),
                  Text(
                    'SMART INSIGHTS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Understand your room\nmore clearly.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _HeroStatistic(
                      value: '$recordCount',
                      label: 'Records',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HeroStatistic(
                      value: '$alertCount',
                      label: 'Alerts',
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _HeroStatistic(
                      value: '$activeDeviceCount',
                      label: 'Active',
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

class _HeroStatistic extends StatelessWidget {
  const _HeroStatistic({required this.value, required this.label});

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
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
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

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onSelected});

  final HistoryRange selected;
  final ValueChanged<HistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: HistoryRange.values.map((range) {
          final isSelected = selected == range;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                onSelected(range);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  switch (range) {
                    HistoryRange.hour => '1 hour',
                    HistoryRange.day => '24 hours',
                    HistoryRange.week => '7 days',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.lightText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.selected, required this.onSelected});

  final HistoryMetric selected;
  final ValueChanged<HistoryMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: HistoryMetric.values.map((metric) {
          final isSelected = metric == selected;

          final accent = _metricColor(metric);

          return Padding(
            padding: const EdgeInsets.only(right: 9),
            child: ChoiceChip(
              selected: isSelected,
              showCheckmark: false,
              selectedColor: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.76),
              side: BorderSide.none,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _metricIcon(metric),
                    size: 17,
                    color: isSelected ? Colors.white : accent,
                  ),
                  const SizedBox(width: 7),
                  Text(_metricName(metric)),
                ],
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.lightText,
                fontWeight: FontWeight.w700,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              onSelected: (_) {
                onSelected(metric);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SensorChartCard extends StatelessWidget {
  const _SensorChartCard({required this.history, required this.records});

  final HistoryProvider history;
  final List<HistoryRecord> records;

  @override
  Widget build(BuildContext context) {
    final accent = _metricColor(history.selectedMetric);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(29),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_metricIcon(history.selectedMetric), color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.metricTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${records.length} recorded values',
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatValue(history.averageValue)} ${history.metricUnit}',
                style: TextStyle(
                  color: accent,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 250,
            child: records.length < 2
                ? const Center(
                    child: Text(
                      'Waiting for more sensor records...',
                      style: TextStyle(color: AppColors.lightTextSecondary),
                    ),
                  )
                : LineChart(
                    _buildChartData(history, records, accent),
                    duration: const Duration(milliseconds: 350),
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(
    HistoryProvider history,
    List<HistoryRecord> records,
    Color accent,
  ) {
    final spots = <FlSpot>[];

    for (var index = 0; index < records.length; index++) {
      spots.add(
        FlSpot(index.toDouble(), history.valueForRecord(records[index])),
      );
    }

    final values = spots.map((spot) => spot.y).toList();

    final rawMinimum = values.reduce((a, b) => a < b ? a : b);

    final rawMaximum = values.reduce((a, b) => a > b ? a : b);

    final padding = math.max(1.0, (rawMaximum - rawMinimum) * 0.18);

    final minimumY = math.max(0.0, rawMinimum - padding);

    final maximumY = rawMaximum + padding;

    final verticalInterval = math.max(1.0, (maximumY - minimumY) / 4);

    final xInterval = math.max(1.0, (records.length - 1) / 3);

    return LineChartData(
      minX: 0,
      maxX: (records.length - 1).toDouble(),
      minY: minimumY,
      maxY: maximumY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: verticalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.black.withValues(alpha: 0.055),
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 43,
            interval: verticalInterval,
            getTitlesWidget: (value, metadata) {
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: Text(
                  _compactValue(value),
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: xInterval,
            getTitlesWidget: (value, metadata) {
              final index = value.round().clamp(0, records.length - 1);

              final time = records[index].createdAt;

              final label = switch (history.selectedRange) {
                HistoryRange.hour => DateFormat('h:mm').format(time),
                HistoryRange.day => DateFormat('h a').format(time),
                HistoryRange.week => DateFormat('E').format(time),
              };

              return Padding(
                padding: const EdgeInsets.only(top: 9),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: const LineTouchData(enabled: true),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true,
          color: accent,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: accent.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.history});

  final HistoryProvider history;

  @override
  Widget build(BuildContext context) {
    final accent = _metricColor(history.selectedMetric);

    final trend = history.trendValue;

    final trendPositive = trend >= 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _StatisticCard(
          label: 'Average',
          value: '${_formatValue(history.averageValue)} ${history.metricUnit}',
          icon: Icons.functions_rounded,
          accent: accent,
        ),
        _StatisticCard(
          label: 'Highest',
          value: '${_formatValue(history.maximumValue)} ${history.metricUnit}',
          icon: Icons.arrow_upward_rounded,
          accent: AppColors.danger,
        ),
        _StatisticCard(
          label: 'Lowest',
          value: '${_formatValue(history.minimumValue)} ${history.metricUnit}',
          icon: Icons.arrow_downward_rounded,
          accent: AppColors.accentBlue,
        ),
        _StatisticCard(
          label: 'Trend',
          value:
              '${trendPositive ? '+' : ''}${_formatValue(trend)} ${history.metricUnit}',
          icon: trendPositive
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          accent: trendPositive ? AppColors.warning : AppColors.safe,
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.icon,
    required this.accent,
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color accent;
  final String value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.79),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEventCard extends StatelessWidget {
  const _TimelineEventCard({required this.event});

  final AutomationEvent event;

  @override
  Widget build(BuildContext context) {
    final accent = switch (event.severity) {
      AutomationSeverity.info => AppColors.accentBlue,
      AutomationSeverity.warning => AppColors.warning,
      AutomationSeverity.critical => AppColors.danger,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.isTest ? Icons.science_rounded : Icons.bolt_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a').format(event.createdAt),
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  event.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    height: 1.4,
                    fontSize: 12,
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

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.primaryDark, size: 31),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Automation activity will appear here after a rule runs.',
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                height: 1.45,
              ),
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

Color _metricColor(HistoryMetric metric) {
  return switch (metric) {
    HistoryMetric.temperature => AppColors.temperature,
    HistoryMetric.humidity => AppColors.humidity,
    HistoryMetric.gas => AppColors.gas,
    HistoryMetric.light => AppColors.light,
  };
}

IconData _metricIcon(HistoryMetric metric) {
  return switch (metric) {
    HistoryMetric.temperature => Icons.thermostat_rounded,
    HistoryMetric.humidity => Icons.water_drop_rounded,
    HistoryMetric.gas => Icons.cloud_rounded,
    HistoryMetric.light => Icons.wb_sunny_rounded,
  };
}

String _metricName(HistoryMetric metric) {
  return switch (metric) {
    HistoryMetric.temperature => 'Temperature',
    HistoryMetric.humidity => 'Humidity',
    HistoryMetric.gas => 'Gas',
    HistoryMetric.light => 'Light',
  };
}

String _formatValue(double value) {
  if (value.abs() >= 100) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}

String _compactValue(double value) {
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }

  if (value >= 100) {
    return value.toStringAsFixed(0);
  }

  return value.toStringAsFixed(1);
}
