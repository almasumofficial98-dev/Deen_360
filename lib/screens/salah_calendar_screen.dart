import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_tracker_provider.dart';
import '../widgets/salah_log_sheet.dart';

class SalahCalendarScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const SalahCalendarScreen({super.key, required this.onNavigate});

  @override
  State<SalahCalendarScreen> createState() => _SalahCalendarScreenState();
}

class _SalahCalendarScreenState extends State<SalahCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final tracker = context.watch<SalahTrackerProvider>();
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(primaryColor),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _buildHeroSummary(tracker, primaryColor),
                  const SizedBox(height: 20),
                  _buildCalendarSection(tracker, primaryColor),
                  const SizedBox(height: 24),
                  _buildDayDetails(tracker, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.onNavigate('home'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.dynamicSoft(primary),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: primary, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DAILY TRACKER',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Salah Calendar',
                  style: TextStyle(
                    color: AppTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onNavigate('salahGuide'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, color: primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Guide',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummary(SalahTrackerProvider tracker, Color primary) {
    final streak = tracker.getCurrentStreak();
    final monthlyStats = tracker.getMonthlyStats(_focusedDay);
    final totalLogged = monthlyStats['totalLogged'] ?? 0;
    final maxPossible = monthlyStats['maxPossible'] ?? 150;
    final jamaatCount = monthlyStats['jamaatCount'] ?? 0;
    final progressRatio = (totalLogged / (maxPossible > 0 ? maxPossible : 1)).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.dynamicFloating(primary),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '$streak Day Streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              // Jamaat Ratio
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$jamaatCount Jamaat',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$totalLogged',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        ' / $maxPossible Prayers',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${(progressRatio * 100).round()}% Completed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(SalahTrackerProvider tracker, Color primary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.dynamicSoft(primary),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: TableCalendar(
        rowHeight: 56,
        daysOfWeekHeight: 28,
        firstDay: tracker.installDate,
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          formatButtonTextStyle: TextStyle(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: primary, size: 24),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: primary, size: 24),
          titleTextStyle: const TextStyle(
            color: AppTheme.text,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          weekendStyle: TextStyle(
            color: AppTheme.textLight,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, tracker, primary, isSelected: false, isToday: false),
          todayBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, tracker, primary, isSelected: isSameDay(_selectedDay, day), isToday: true),
          selectedBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, tracker, primary, isSelected: true, isToday: isSameDay(DateTime.now(), day)),
        ),
      ),
    );
  }

  Widget _buildCustomDayCell(
    DateTime day,
    SalahTrackerProvider tracker,
    Color primary, {
    required bool isSelected,
    required bool isToday,
  }) {
    final count = tracker.getCompletedCount(day);

    BoxDecoration decoration;
    Color textColor = AppTheme.text;
    Widget? subtitleWidget;

    if (isSelected) {
      decoration = BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.dynamicSoft(primary),
      );
      textColor = Colors.white;
      if (count == 5) {
        subtitleWidget = const Icon(Icons.star_rounded, size: 10, color: Colors.amberAccent);
      } else if (count > 0) {
        subtitleWidget = Text('$count/5', style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold));
      }
    } else if (count == 5) {
      decoration = BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.5),
      );
      textColor = const Color(0xFF047857);
      subtitleWidget = const Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF10B981));
    } else if (count > 0) {
      decoration = BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      );
      textColor = primary;
      subtitleWidget = Text('$count/5', style: TextStyle(color: primary, fontSize: 9, fontWeight: FontWeight.bold));
    } else if (isToday) {
      decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary, width: 2),
      );
      textColor = primary;
    } else {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      );
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: decoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected || isToday || count > 0 ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            if (subtitleWidget != null) ...[
              const SizedBox(height: 1),
              subtitleWidget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetails(SalahTrackerProvider tracker, Color primary) {
    if (_selectedDay == null) return const SizedBox();

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_selectedDay!);
    final completedCount = tracker.getCompletedCount(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppTheme.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap any prayer to update status',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (completedCount == 5 ? const Color(0xFF10B981) : primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (completedCount == 5 ? const Color(0xFF10B981) : primary).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$completedCount / 5 Completed',
                  style: TextStyle(
                    color: completedCount == 5 ? const Color(0xFF047857) : primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...prayers.map((p) => _buildPrayerItem(p, tracker, primary)),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(
    String name,
    SalahTrackerProvider tracker,
    Color primary,
  ) {
    final entry = tracker.getEntry(_selectedDay!, name);

    IconData statusIcon = Icons.add_circle_outline_rounded;
    Color statusColor = AppTheme.textMuted;
    String statusLabel = 'Not Logged';
    Color leftBarColor = const Color(0xFFE2E8F0);

    switch (entry.status) {
      case SalahStatus.alone:
        statusIcon = Icons.person_rounded;
        statusColor = primary;
        statusLabel = 'Alone';
        leftBarColor = primary;
      case SalahStatus.jamaat:
        statusIcon = Icons.groups_rounded;
        statusColor = const Color(0xFF10B981);
        statusLabel = 'In Jamaat (+27x)';
        leftBarColor = const Color(0xFF10B981);
      case SalahStatus.qaza:
        statusIcon = Icons.history_rounded;
        statusColor = Colors.amber.shade900;
        statusLabel = 'Qaza';
        leftBarColor = Colors.amber;
      case SalahStatus.missed:
        statusIcon = Icons.close_rounded;
        statusColor = const Color(0xFFF43F5E);
        statusLabel = 'Missed';
        leftBarColor = const Color(0xFFF43F5E);
      case SalahStatus.none:
        break;
    }

    // Prayer Specific Icon & Gradient
    IconData prayerIcon = Icons.access_time_rounded;
    List<Color> prayerGradient = [Colors.blue, Colors.lightBlue];

    switch (name) {
      case 'Fajr':
        prayerIcon = Icons.wb_twilight_rounded;
        prayerGradient = [const Color(0xFFFF7E5F), const Color(0xFFFEB47B)];
      case 'Dhuhr':
        prayerIcon = Icons.wb_sunny_rounded;
        prayerGradient = [const Color(0xFFF7971E), const Color(0xFFFFD200)];
      case 'Asr':
        prayerIcon = Icons.wb_cloudy_rounded;
        prayerGradient = [const Color(0xFF36D1DC), const Color(0xFF5B86E5)];
      case 'Maghrib':
        prayerIcon = Icons.nights_stay_rounded;
        prayerGradient = [const Color(0xFF4568DC), const Color(0xFFB06AB3)];
      case 'Isha':
        prayerIcon = Icons.dark_mode_rounded;
        prayerGradient = [const Color(0xFF0F2027), const Color(0xFF2C5364)];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.dynamicSoft(leftBarColor),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SalahLogSheet(
                date: _selectedDay!,
                prayerName: name,
                onNavigate: widget.onNavigate,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Prayer Gradient Icon Box
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: prayerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: prayerGradient.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(prayerIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildDetailTags(entry, primary),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTags(SalahEntry entry, Color primary) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.sunnahBefore > 0)
            _buildMiniTag('${entry.sunnahBefore} Sunnah', Colors.amber.shade900),
          if (entry.sunnahAfter > 0) ...[
            const SizedBox(width: 4),
            _buildMiniTag('${entry.sunnahAfter} Sunnah', Colors.orange.shade900),
          ],
          if (entry.witr > 0) ...[
            const SizedBox(width: 4),
            _buildMiniTag('${entry.witr} Witr', Colors.indigo),
          ],
          if (entry.nafl > 0) ...[
            const SizedBox(width: 4),
            _buildMiniTag('${entry.nafl} Nafl', Colors.purple),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
