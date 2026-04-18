import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';
import '../data/salah_repository.dart';

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
  String _weatherEmoji = '☀️';

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

  // Daily tracker
  Map<String, bool> _prayerTracker = {
    'Fajr': false, 'Dhuhr': false, 'Asr': false, 'Maghrib': false, 'Isha': false
  };
  int _prayerProgress = 0;

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
    await _loadPrayerTracker();

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
    // Fetch both in parallel
    final results = await Future.wait([
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
        _tick(); // Immediately calculate current prayer block
      }
    } catch (e) {
      print('fetchSalahTimings error: $e');
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
          final code = cw['weathercode'] as int;
          String emoji = code == 0 ? '☀️' : code <= 3 ? '⛅' : code <= 48 ? '🌫️' : code <= 65 ? '🌧️' : code <= 75 ? '❄️' : code <= 82 ? '🌦️' : '⛈️';
          setState(() { _temperature = temp; _weatherEmoji = emoji; });
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

      // Reverse geocode
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

      // Save
      await repo.saveUserLocation(LocationData(latitude: pos.latitude, longitude: pos.longitude, city: city));

      if (mounted) {
        setState(() => _locationName = city);
        _fetchTimingsAndWeather(pos.latitude, pos.longitude);
      }
    } catch (e) {
      print('GPS background: $e');
    }
  }

  // ─────────────────────────────────────────
  //  PRAYER BLOCK CALCULATION (core logic)
  // ─────────────────────────────────────────

  /// Called every second by the timer
  void _tick() {
    if (!mounted || _timings == null) return;
    _calculateCurrentBlock(DateTime.now());
  }

  /// Parse "HH:MM" from Aladhan into a DateTime on [baseDate].
  /// If the result is before [afterTime], assumes it's the next day.
  DateTime _parseTime(String? raw, DateTime baseDate, {DateTime? afterTime}) {
    if (raw == null || raw.isEmpty) return baseDate;
    final cleaned = raw.split(' ')[0]; // strip "(IST)" etc
    final parts = cleaned.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    var dt = DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
    if (afterTime != null && dt.isBefore(afterTime)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  /// Main prayer block resolver
  /// 
  /// Aladhan returns: Imsak, Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Midnight, Firstthird, Lastthird
  ///
  /// The blocks for 24h cycle are:
  ///   Maghrib  → Isha      (Maghrib time)
  ///   Isha     → Midnight  (Isha time — first part of night)
  ///   Midnight → Fajr      (Tahajjud / last third of night)
  ///   Fajr     → Sunrise   (Fajr prayer time)
  ///   Sunrise  → Dhuhr     (Ishraq / Duha — no fard)
  ///   Dhuhr    → Asr       (Dhuhr prayer time)
  ///   Asr      → Sunset    (Asr prayer time)
  ///   Sunset   → Maghrib   (Sunset — very brief or same as Maghrib)
  void _calculateCurrentBlock(DateTime now) {
    final t = _timings!;
    final today = DateTime(now.year, now.month, now.day);

    // Parse all times
    final fajr     = _parseTime(t['Fajr'] as String?, today);
    final sunrise  = _parseTime(t['Sunrise'] as String?, today);
    final dhuhr    = _parseTime(t['Dhuhr'] as String?, today);
    final asr      = _parseTime(t['Asr'] as String?, today);
    final sunset   = _parseTime(t['Sunset'] as String?, today);
    final maghrib  = _parseTime(t['Maghrib'] as String?, today);
    final isha     = _parseTime(t['Isha'] as String?, today);
    final midnight = _parseTime(t['Midnight'] as String?, today, afterTime: isha);
    final tomorrowFajr = fajr.add(const Duration(days: 1));

    // ── EARLY MORNING EDGE: before Fajr today ──
    if (now.isBefore(fajr)) {
      final midnightToday = _parseTime(t['Midnight'] as String?, today);

      // Before midnight (e.g. 00:05 and midnight is 00:20) → still Isha
      if (now.isBefore(midnightToday)) {
        final diff = midnightToday.difference(now);
        _setHUD('ISHA', 'Isha Salah', 'Midnight', _fmt12(isha.subtract(const Duration(days: 1))), _fmt12(midnightToday), _fmt12(midnightToday), diff);
        return;
      }

      // After midnight, before Fajr → Tahajjud
      final diff = fajr.difference(now);
      _setHUD('TAHAJJUD', 'Last Third of Night', 'Fajr', _fmt12(midnightToday), _fmt12(fajr), _fmt12(fajr), diff);
      return;
    }

    // ── NORMAL DAYTIME BLOCKS ──
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

    // Ultimate fallback
    _setHUD('--', 'Calculating...', '--', '--', '--', '--', Duration.zero);
  }

  void _setHUD(String name, String label, String nextName, String start, String end, String nextTime, Duration diff) {
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    setState(() {
      _currentPrayerName = name;
      _currentPrayerLabel = label;
      _nextPrayerName = nextName;
      _currentStart = start;
      _currentEnd = end;
      _nextTime = nextTime;
      _timeRemaining = diff.inSeconds <= 0 ? '00:00:00' : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    });
  }

  /// Formats a DateTime to 12h string
  String _fmt12(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  /// Formats an Aladhan time string "HH:MM" to 12h


  // ─────────────────────────────────────────
  //  PRAYER TRACKER
  // ─────────────────────────────────────────

  Future<void> _loadPrayerTracker() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('deen360_salah_tracker');
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (saved != null) {
        final parsed = jsonDecode(saved);
        if (parsed['date'] == today && parsed['data'] != null) {
          final Map<String, dynamic> data = parsed['data'];
          final tracker = <String, bool>{};
          data.forEach((k, v) => tracker[k] = v == true);
          if (mounted) {
            setState(() {
              _prayerTracker = tracker;
              _prayerProgress = tracker.values.where((v) => v).length;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _togglePrayer(String name) async {
    setState(() {
      _prayerTracker[name] = !(_prayerTracker[name] ?? false);
      _prayerProgress = _prayerTracker.values.where((v) => v).length;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString('deen360_salah_tracker', jsonEncode({'date': today, 'data': _prayerTracker}));
    } catch (_) {}
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
              _buildSectionHeader('Journey Roadmap'),
              _buildSpiritualRoadmap(),
              _buildDailyTracker(),
              _buildSectionHeader('Spiritual Insight'),
              _buildDailyAyah(),
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
          boxShadow: AppShadows.floating,
        ),
        child: Column(
          children: [
            // Top Row: Location & Weather
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
                        const Text('📍', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(_locationName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_weatherEmoji ${_temperature != null ? "$_temperature°C" : "--°C"}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hero: Prayer Name + Countdown
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
                        child: Text(
                          _currentPrayerName,
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.08),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPrayerLabel.isNotEmpty ? _currentPrayerLabel : 'Current Period',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
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
                        child: Text(
                          _timeRemaining,
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Until $_nextPrayerName',
                        style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 20),

            // Bottom stats
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
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // ─────────────── ROADMAP ───────────────
  Widget _buildSpiritualRoadmap() {
    final items = [
      {'title': 'Al-Quran', 'sub': 'The Divine Word', 'icon': Icons.menu_book_rounded, 'route': 'surahList', 'isHero': true},
      {'title': 'Daily Hadith', 'sub': 'Prophetic Wisdom', 'icon': Icons.star_rounded, 'route': 'hadiths', 'isHero': false},
      {'title': '99 Names of Allah', 'sub': 'Attributes of Allah', 'icon': Icons.favorite_rounded, 'route': 'asma', 'isHero': false},
      {'title': 'Qibla Compass', 'sub': 'Kaaba alignment', 'icon': Icons.explore_rounded, 'route': 'qibla', 'isHero': false},
      {'title': 'Dua Collection', 'sub': 'Hisnul Muslim', 'icon': Icons.chat_bubble_rounded, 'route': 'duaCategories', 'isHero': false},
      {'title': 'Salah Schedule', 'sub': 'Daily timings', 'icon': Icons.calendar_today_rounded, 'route': 'salah', 'isHero': false},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: items.map((item) {
          final isHero = item['isHero'] as bool;
          return Padding(
            padding: EdgeInsets.only(bottom: isHero ? 10 : 0),
            child: Material(
              color: isHero ? AppTheme.surface : Colors.transparent,
              borderRadius: isHero ? BorderRadius.circular(24) : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(isHero ? 24 : 0),
                onTap: () => widget.onNavigate(item['route'] as String),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: isHero ? 20 : 10),
                  decoration: isHero ? null : BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.inputBg, width: 1))),
                  child: Row(
                    children: [
                      Container(
                        width: isHero ? 54 : 48, height: isHero ? 54 : 48,
                        decoration: BoxDecoration(
                          color: isHero ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(isHero ? 27 : 24),
                        ),
                        child: Icon(item['icon'] as IconData, size: isHero ? 28 : 22, color: isHero ? Colors.white : AppTheme.primary),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] as String, style: TextStyle(color: AppTheme.text, fontSize: isHero ? 20 : 17, fontWeight: isHero ? FontWeight.w900 : FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(item['sub'] as String, style: const TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('→', style: TextStyle(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.w800))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────── DAILY TRACKER ───────────────
  Widget _buildDailyTracker() {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 30, 30, 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Tracker', style: TextStyle(color: AppTheme.text, fontSize: 18, fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.show_chart_rounded, size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text('$_prayerProgress/5', style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w900)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: AppShadows.soft,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                final done = _prayerTracker[p] == true;
                return GestureDetector(
                  onTap: () => _togglePrayer(p),
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: done ? AppTheme.primary : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(22)),
                      child: done ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                    ),
                    const SizedBox(height: 8),
                    Text(p, style: TextStyle(color: done ? AppTheme.primary : const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── DAILY AYAH ───────────────
  Widget _buildDailyAyah() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => widget.onNavigate('surahList'),
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.floating),
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
            const Text('Surah Ar-Ra\'d [13:28]', style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Prayer Block Model
// ─────────────────────────────────────────

class _PrayerBlock {
  final String name;       // e.g. "FAJR"
  final String label;      // e.g. "Fajr Salah"
  final DateTime start;
  final DateTime end;
  final String nextName;   // e.g. "Sunrise"
  final String nextTimeStr;
  final bool isFard;

  _PrayerBlock(this.name, this.label, this.start, this.end, this.nextName, this.nextTimeStr, this.isFard);
}
