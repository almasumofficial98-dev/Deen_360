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
                  _buildCalendar(tracker, primaryColor),
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
      padding: const EdgeInsets.all(24),
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
              ),
              child: Icon(Icons.arrow_back_rounded, color: primary, size: 20),
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SALAH HISTORY', style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text('Prayer Calendar', style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => widget.onNavigate('salahGuide'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.info_outline_rounded, color: primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(SalahTrackerProvider tracker, Color primary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.dynamicSoft(primary),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: TableCalendar(
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
        eventLoader: (day) {
          final count = tracker.getCompletedCount(day);
          return count > 0 ? List.generate(count, (index) => 'done') : [];
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: primary.withValues(alpha: 0.2), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
          markersMaxCount: 5,
          markerDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDayDetails(SalahTrackerProvider tracker, Color primary) {
    if (_selectedDay == null) return const SizedBox();

    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final dateStr = DateFormat('EEEE, d MMMM').format(_selectedDay!);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: const TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w900)),
              Text('${tracker.getCompletedCount(_selectedDay!)}/5 Done', 
                style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          ...prayers.map((p) => _buildPrayerItem(p, tracker, primary)),
        ],
      ),
    );
  }

  Widget _buildPrayerItem(String name, SalahTrackerProvider tracker, Color primary) {
    final entry = tracker.getEntry(_selectedDay!, name);
    
    IconData statusIcon = Icons.circle_outlined;
    Color statusColor = AppTheme.textMuted;
    String statusLabel = 'Not Logged';

    switch (entry.status) {
      case SalahStatus.alone:
        statusIcon = Icons.check_circle_rounded;
        statusColor = primary;
        statusLabel = 'Alone';
      case SalahStatus.jamaat:
        statusIcon = Icons.groups_rounded;
        statusColor = primary;
        statusLabel = 'In Jamaat';
      case SalahStatus.qaza:
        statusIcon = Icons.history_rounded;
        statusColor = Colors.orange;
        statusLabel = 'Qaza';
      case SalahStatus.missed:
        statusIcon = Icons.close_rounded;
        statusColor = Colors.red;
        statusLabel = 'Missed';
      case SalahStatus.none:
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SalahLogSheet(date: _selectedDay!, prayerName: name),
          );
        },
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: AppTheme.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDetailTags(entry, primary),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTags(SalahEntry entry, Color primary) {
    return Row(
      children: [
        if (entry.sunnahBefore > 0) _buildMiniTag('${entry.sunnahBefore}B', Colors.amber),
        if (entry.sunnahAfter > 0) ...[const SizedBox(width: 4), _buildMiniTag('${entry.sunnahAfter}A', Colors.orange)],
        if (entry.witr > 0) ...[const SizedBox(width: 4), _buildMiniTag('Witr', Colors.indigo)],
        if (entry.nafl > 0) ...[const SizedBox(width: 4), _buildMiniTag('N', Colors.purple)],
      ],
    );
  }

  Widget _buildMiniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
