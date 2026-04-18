import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_repository.dart';
import '../data/salah_tracker_provider.dart';
import '../widgets/salah_log_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Location & Weather
  String _locationName = 'Loading...';
  int? _temperature;
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  // Prayer data from Aladhan
  Map<String, dynamic>? _timings;

  // Computed prayer HUD state
  String _currentPrayerName = 'LOADING';
  String _currentPrayerLabel = '';
  String _nextPrayerName = '--';
  String _timeRemaining = '--:--:--';
  String _currentStart = '--';
  String _currentEnd = '--';
  String _nextTime = '--';

  Timer? _clockTimer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _initData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  //  DATA INIT
  // ─────────────────────────────────────────

  Future<void> _initData() async {
    final salahRepo = context.read<SalahRepository>();

    // 1. Try saved location for instant display
    final saved = await salahRepo.getUserLocation();
    if (saved != null) {
      if (mounted) setState(() => _locationName = saved.city ?? 'Saved');
      _fetchTimingsAndWeather(saved.latitude, saved.longitude);
    } else {
      // No saved location — use Makkah as default so we show data immediately
      if (mounted) setState(() => _locationName = 'Makkah');
      _fetchTimingsAndWeather(21.4225, 39.8262);
    }

    // 2. Live GPS in background (non-blocking)
    _fetchGPSInBackground(salahRepo, saved);
  }

  Future<void> _fetchTimingsAndWeather(double lat, double lng) async {
    await Future.wait([
      _fetchSalahTimings(lat, lng),
      _fetchWeather(lat, lng),
    ]);
  }

  Future<void> _fetchSalahTimings(double lat, double lng) async {
    try {
      final salahRepo = context.read<SalahRepository>();
      final t = await salahRepo.getSalahTimingsByCoordinates(lat, lng);
      if (t != null && mounted) {
        setState(() => _timings = t);
        _tick(); 
      }
    } catch (e) {
      debugPrint('fetchSalahTimings error: $e');
    }
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final cw = data['current_weather'];
        if (cw != null) {
          final temp = (cw['temperature'] as num).round();
          final code = (cw['weathercode'] as num?)?.toInt() ?? 0;
          IconData icon = Icons.wb_sunny_rounded;
          if (code == 0) icon = Icons.wb_sunny_rounded;
          else if (code <= 3) icon = Icons.wb_cloudy_rounded;
          else if (code <= 48) icon = Icons.filter_drama_rounded;
          else if (code <= 65) icon = Icons.beach_access_rounded;
          else if (code <= 75) icon = Icons.ac_unit_rounded;
          else if (code <= 82) icon = Icons.umbrella_rounded;
          else icon = Icons.thunderstorm_rounded;
          
          setState(() { _temperature = temp; _weatherIcon = icon; });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchGPSInBackground(SalahRepository repo, LocationData? saved) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 10)),
      );

      String city = 'Lat ${pos.latitude.toStringAsFixed(1)}';
      try {
        final geoRes = await http.get(
          Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=10'),
          headers: {'User-Agent': 'Deen360/1.0'},
        ).timeout(const Duration(seconds: 8));
        if (geoRes.statusCode == 200) {
          final addr = jsonDecode(geoRes.body)['address'];
          city = addr?['city'] ?? addr?['town'] ?? addr?['village'] ?? addr?['county'] ?? city;
        }
      } catch (_) {}

      await repo.saveUserLocation(LocationData(latitude: pos.latitude, longitude: pos.longitude, city: city));

      if (mounted) {
        setState(() => _locationName = city);
        _fetchTimingsAndWeather(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('GPS background: $e');
    }
  }

  void _tick() {
    if (!mounted || _timings == null) return;
    _calculateCurrentBlock(DateTime.now());
  }

  DateTime _parseTime(String? raw, DateTime baseDate, {DateTime? afterTime}) {
    if (raw == null || raw.isEmpty) return baseDate;
    final cleaned = raw.split(' ')[0]; 
    final parts = cleaned.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    var dt = DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
    if (afterTime != null && dt.isBefore(afterTime)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  void _calculateCurrentBlock(DateTime now) {
    if (_timings == null) return;
    final t = _timings!;
    final today = DateTime(now.year, now.month, now.day);

    final fajr     = _parseTime(t['Fajr'] as String?, today);
    final sunrise  = _parseTime(t['Sunrise'] as String?, today);
    final dhuhr    = _parseTime(t['Dhuhr'] as String?, today);
    final asr      = _parseTime(t['Asr'] as String?, today);
    final sunset   = _parseTime(t['Sunset'] as String?, today);
    final maghrib  = _parseTime(t['Maghrib'] as String?, today);
    final isha     = _parseTime(t['Isha'] as String?, today);
    final midnight = _parseTime(t['Midnight'] as String?, today, afterTime: isha);
    final tomorrowFajr = fajr.add(const Duration(days: 1));

    if (now.isBefore(fajr)) {
      final midnightToday = _parseTime(t['Midnight'] as String?, today);
      if (now.isBefore(midnightToday)) {
        final diff = midnightToday.difference(now);
        _setHUD('ISHA', 'Isha Salah', 'Midnight', _fmt12(isha.subtract(const Duration(days: 1))), _fmt12(midnightToday), _fmt12(midnightToday), diff);
        return;
      }
      final diff = fajr.difference(now);
      _setHUD('TAHAJJUD', 'Last Third of Night', 'Fajr', _fmt12(midnightToday), _fmt12(fajr), _fmt12(fajr), diff);
      return;
    }

    final blocks = <_PrayerBlock>[
      _PrayerBlock('FAJR',      'Fajr Salah',        fajr,     sunrise,      'Sunrise',   _fmt12(sunrise),  true),
      _PrayerBlock('SUNRISE',   'Ishraq / Duha',     sunrise,  dhuhr,        'Dhuhr',     _fmt12(dhuhr),    false),
      _PrayerBlock('DHUHR',     'Dhuhr Salah',       dhuhr,    asr,          'Asr',       _fmt12(asr),      true),
      _PrayerBlock('ASR',       'Asr Salah',         asr,      sunset,       'Maghrib',   _fmt12(maghrib),  true),
      _PrayerBlock('MAGHRIB',   'Maghrib Salah',     maghrib,  isha,         'Isha',      _fmt12(isha),     true),
      _PrayerBlock('ISHA',      'Isha Salah',        isha,     midnight,     'Midnight',  _fmt12(midnight), true),
      _PrayerBlock('MIDNIGHT',  'Tahajjud / Qiyam',  midnight, tomorrowFajr, 'Fajr',      _fmt12(tomorrowFajr), false),
    ];

    for (final block in blocks) {
      if ((now.isAfter(block.start) || now.isAtSameMomentAs(block.start)) && now.isBefore(block.end)) {
        final diff = block.end.difference(now);
        _setHUD(block.name, block.label, block.nextName, _fmt12(block.start), _fmt12(block.end), block.nextTimeStr, diff);
        return;
      }
    }

    _setHUD('--', 'Calculating...', '--', '--', '--', '--', Duration.zero);
  }

  void _setHUD(String name, String label, String nextName, String start, String end, String nextTime, Duration diff) {
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (mounted) {
      setState(() {
        _currentPrayerName = name;
        _currentPrayerLabel = label;
        _nextPrayerName = nextName;
        _currentStart = start;
        _currentEnd = end;
        _nextTime = nextTime;
        _timeRemaining = diff.inSeconds <= 0 ? '00:00:00' : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
      if (name != '--') {
        context.read<ThemeProvider>().updateFromPrayerBlock(name);
      }
    }
  }

  String _fmt12(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  // ─────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildZenHUD(),
              _buildDailyTracker(context),
              _buildSectionHeader('Community & Share'),
              _buildShareQuran(context),
              _buildSectionHeader('Spiritual Insight'),
              _buildDailyAyah(context),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, bottom: 20),
      child: Text(title, style: const TextStyle(color: AppTheme.text, fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }

  // ─────────────── ZEN HUD ───────────────
  LinearGradient _getHUDGradient() {
    switch (_currentPrayerName) {
      case 'FAJR':
      case 'SUNRISE':
        return AppGradients.dawn;
      case 'DHUHR':
      case 'ASR':
        return AppGradients.primary;
      case 'MAGHRIB':
        return AppGradients.sunset;
      case 'ISHA':
      case 'MIDNIGHT':
      case 'TAHAJJUD':
      case 'TAHAJJUD_VIGIL':
        return AppGradients.night;
      default:
        return AppGradients.primary;
    }
  }

  Widget _buildZenHUD() {
    final gradient = _getHUDGradient();

    return GestureDetector(
      onTap: () => widget.onNavigate('salah'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(_locationName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Icon(_weatherIcon, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      '${_temperature != null ? "$_temperature°C" : "--°C"}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_currentPrayerName, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.08)),
                      ),
                      const SizedBox(height: 2),
                      Text(_currentPrayerLabel.isNotEmpty ? _currentPrayerLabel : 'Current Period', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  flex: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(_timeRemaining, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text('Until $_nextPrayerName', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatItem('Started', _currentStart),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                _buildStatItem('Ending', _currentEnd),
                Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.15)),
                _buildStatItem('$_nextPrayerName at', _nextTime),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ─────────────── DAILY TRACKER ───────────────
  Widget _buildDailyTracker(BuildContext context) {
    final tracker = context.watch<SalahTrackerProvider>();
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final progress = tracker.getCompletedCount(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Tracker', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w900)),
              GestureDetector(
                onTap: () => widget.onNavigate('salahCalendar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 8),
                    Text('$progress/5', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 14, color: primaryColor),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)), 
              boxShadow: AppShadows.dynamicSoft(primaryColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                final entry = tracker.getEntry(DateTime.now(), p);
                final isDone = entry.status == SalahStatus.alone || entry.status == SalahStatus.jamaat || entry.status == SalahStatus.qaza;
                final isMissed = entry.status == SalahStatus.missed;
                
                Color ballColor = const Color(0xFFF1F5F9);
                Widget? icon;
                if (isDone) {
                  ballColor = primaryColor;
                  icon = const Icon(Icons.check_rounded, color: Colors.white, size: 18);
                } else if (isMissed) {
                  ballColor = Colors.red.withValues(alpha: 0.1);
                  icon = const Icon(Icons.close_rounded, color: Colors.red, size: 18);
                }

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SalahLogSheet(date: DateTime.now(), prayerName: p),
                    );
                  },
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: ballColor, borderRadius: BorderRadius.circular(22)),
                      child: icon,
                    ),
                    const SizedBox(height: 8),
                    Text(p, style: TextStyle(color: isDone ? primaryColor : (isMissed ? Colors.red : const Color(0xFF94A3B8)), fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── SHARE QURAN ───────────────
  Widget _buildShareQuran(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: AppShadows.dynamicSoft(theme.primaryColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.share_rounded, color: theme.primaryColor, size: 24),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Share the Light', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w900)),
                      SizedBox(height: 2),
                      Text('Send Quranic Ayahs to loved ones', style: TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildShareOption(context, 'Daily Ayah', Icons.auto_stories_rounded, () => widget.onNavigate('surahList'))),
                const SizedBox(width: 12),
                Expanded(child: _buildShareOption(context, 'Noble Quran', Icons.menu_book_rounded, () => widget.onNavigate('surahList'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAyah(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => widget.onNavigate('surahList'),
        child: Container(
          decoration: BoxDecoration(
            gradient: theme.activeGradient, 
            borderRadius: BorderRadius.circular(28), 
            boxShadow: AppShadows.dynamicFloating(theme.primaryColor)
          ),
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [Icon(Icons.auto_stories_rounded, size: 14, color: Colors.white), SizedBox(width: 6), Text('DAILY AYAH', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))]),
              ),
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.share_rounded, size: 16, color: Colors.white)),
            ]),
            const SizedBox(height: 15),
            Icon(Icons.format_quote_rounded, size: 32, color: Colors.white.withValues(alpha: 0.2)),
            const SizedBox(height: 10),
            const Text('"أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('"Verily, in the remembrance of Allah do hearts find rest."', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, fontWeight: FontWeight.w600, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text('Surah Ar-Ra\'d [13:28]', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

class _PrayerBlock {
  final String name; 
  final String label;
  final DateTime start;
  final DateTime end;
  final String nextName;
  final String nextTimeStr;
  final bool isFard;
  _PrayerBlock(this.name, this.label, this.start, this.end, this.nextName, this.nextTimeStr, this.isFard);
}
