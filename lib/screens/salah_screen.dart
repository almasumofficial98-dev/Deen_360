import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_repository.dart';

class SalahScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const SalahScreen({super.key, required this.onNavigate});

  @override
  State<SalahScreen> createState() => _SalahScreenState();
}

class _SalahScreenState extends State<SalahScreen> {
  Map<String, dynamic>? _timings;
  bool _loading = true;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _fetchTimings();
  }

  Future<void> _fetchTimings() async {
    final repo = context.read<SalahRepository>();
    final saved = await repo.getUserLocation();
    double lat = 51.5085, lng = -0.1257;
    String name = 'London';
    if (saved != null) {
      lat = saved.latitude;
      lng = saved.longitude;
      name = saved.city ?? 'Current Location';
    }
    final t = await repo.getSalahTimingsByCoordinates(lat, lng);
    if (mounted) setState(() { _timings = t; _loading = false; _locationName = name; });
  }

  @override
  Widget build(BuildContext context) {
    // Extended prayer list including night periods
    final prayers = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Midnight'];
    final icons = [
      Icons.wb_twilight_rounded,
      Icons.wb_sunny_rounded,
      Icons.light_mode_rounded,
      Icons.wb_twilight_rounded,
      Icons.nights_stay_rounded,
      Icons.dark_mode_rounded,
      Icons.nightlight_round,
    ];

    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryColor;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigate('home'),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Icon(Icons.arrow_back_rounded, color: AppTheme.text, size: 20)),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Salah Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
                        const SizedBox(height: 2),
                        Text(_locationName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: _loading
                ?  Center(child: CircularProgressIndicator(color: primaryColor))
                : _timings == null
                  ? const Center(child: Text('Unable to fetch timings.', style: TextStyle(color: AppTheme.textLight)))
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      children: [
                        // Hero
                        Container(
                          decoration: BoxDecoration(
                            gradient: theme.activeGradient, 
                            borderRadius: BorderRadius.circular(30), 
                            boxShadow: AppShadows.dynamicFloating(primaryColor)
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Text('TIMETABLE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ),
                              const SizedBox(height: 16),
                              Text('Daily Prayer Times', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                              const SizedBox(height: 4),
                              Text('Calculated for $_locationName', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Prayer Times List
                        ...List.generate(prayers.length, (i) {
                          final name = prayers[i];
                          final timeRaw = _timings![name] as String?;
                          final time = _fmt(timeRaw);
                          final icon = icons[i];
                          final isCurrent = _isCurrent(name);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isCurrent ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: isCurrent ? Colors.transparent : const Color(0xFFF1F5F9)),
                              boxShadow: isCurrent ? AppShadows.dynamicFloating(primaryColor) : AppShadows.dynamicSoft(primaryColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: isCurrent ? Colors.white.withValues(alpha: 0.15) : primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(child: Icon(icon, size: 22, color: isCurrent ? Colors.white : primaryColor)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isCurrent ? Colors.white : AppTheme.text)),
                                      if (isCurrent) ...[
                                        const SizedBox(height: 2),
                                        Text('Current Period', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.75))),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(time, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isCurrent ? Colors.white : primaryColor)),
                              ],
                            ),
                          );
                        }),

                        // Tahajjud Special Row
                        _buildTahajjudRow(primaryColor),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahajjudRow(Color primaryColor) {
    final t = _timings;
    if (t == null) return const SizedBox();
    
    final start = _fmt(t['Lastthird'] as String?);

    final isCurrent = _isCurrent('Tahajjud');

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCurrent ? primaryColor : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isCurrent ? Colors.transparent : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child:  Center(child: Icon(Icons.auto_awesome_rounded, size: 20, color: isCurrent ? Colors.white : primaryColor)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahajjud', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: isCurrent ? Colors.white : AppTheme.text)),
                const SizedBox(height: 2),
                Text('Last Third of Night', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isCurrent ? Colors.white.withValues(alpha: 0.6) : AppTheme.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(start, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isCurrent ? Colors.white : primaryColor)),
              Text('until Fajr', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isCurrent ? Colors.white.withValues(alpha: 0.5) : AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    final cleaned = raw.split(' ')[0];
    final parts = cleaned.split(':');
    final h24 = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? parts[1] : '00';
    final h = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  bool _isCurrent(String name) {
    if (_timings == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime parse(String? s, [bool addDay = false]) {
      if (s == null) return now;
      final parts = s.split(' ')[0].split(':');
      var dt = DateTime(today.year, today.month, today.day, int.parse(parts[0]), int.parse(parts[1]));
      if (addDay) dt = dt.add(const Duration(days: 1));
      return dt;
    }

    final fajr     = parse(_timings!['Fajr']);
    final sunrise  = parse(_timings!['Sunrise']);
    final dhuhr    = parse(_timings!['Dhuhr']);
    final asr      = parse(_timings!['Asr']);
    final maghrib  = parse(_timings!['Maghrib']);
    final isha     = parse(_timings!['Isha']);
    final midnight = parse(_timings!['Midnight'], isha.hour > 22 && parse(_timings!['Midnight']).hour < 5);
    final last3rd  = parse(_timings!['Lastthird'], isha.hour > 20 && parse(_timings!['Lastthird']).hour < 5);

    if (name == 'Fajr')      return now.isAfter(fajr) && now.isBefore(sunrise);
    if (name == 'Sunrise')   return now.isAfter(sunrise) && now.isBefore(dhuhr);
    if (name == 'Dhuhr')     return now.isAfter(dhuhr) && now.isBefore(asr);
    if (name == 'Asr')       return now.isAfter(asr) && now.isBefore(maghrib);
    if (name == 'Maghrib')   return now.isAfter(maghrib) && now.isBefore(isha);
    if (name == 'Isha')      return now.isAfter(isha) && now.isBefore(midnight);
    if (name == 'Midnight')  return now.isAfter(midnight) && now.isBefore(last3rd);
    if (name == 'Tahajjud')  return now.isAfter(last3rd) && now.isBefore(fajr.add(Duration(days: (now.hour > 12 ? 1 : 0) == 1 ? 1 : 0))); // simplified

    return false;
  }
}
