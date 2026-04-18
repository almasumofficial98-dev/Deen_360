import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_repository.dart';
import '../data/salah_tracker_provider.dart';
import '../widgets/salah_log_sheet.dart';
import '../widgets/location_search_sheet.dart';

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

  // Bookmarks & Progress
  Map<String, dynamic>? _lastBookmark;

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
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
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

  Future<void> _initData({bool forceGPS = false}) async {
    final salahRepo = context.read<SalahRepository>();

    // Load last bookmark
    _loadLastBookmark();

    final saved = await salahRepo.getUserLocation();
    
    // If we have a saved location and it's not a forced GPS reset, use it
    if (saved != null && !forceGPS) {
      if (mounted) setState(() => _locationName = saved.city ?? 'Saved');
      _fetchTimingsAndWeather(saved.latitude, saved.longitude);
      
      // Still refresh GPS in background if it's not a manual selection
      if (!saved.isManual) {
        _fetchGPSInBackground(salahRepo, saved);
      }
    } else {
      // Default to GPS or Makkah
      if (mounted) setState(() => _locationName = 'Locating...');
      _fetchGPSInBackground(salahRepo, null);
    }
  }

  Future<void> _loadLastBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks');
      if (raw != null) {
        final bookmarks = jsonDecode(raw) as List;
        if (bookmarks.isNotEmpty && mounted) {
          setState(() => _lastBookmark = bookmarks.last);
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchTimingsAndWeather(double lat, double lng) async {
    await Future.wait([_fetchSalahTimings(lat, lng), _fetchWeather(lat, lng)]);
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
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current_weather=true',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final cw = data['current_weather'] ?? data['current'];
        if (cw != null) {
          final temp = (cw['temperature'] ?? cw['temperature_2m'] as num).round();
          final code = (cw['weathercode'] ?? cw['weather_code'] as num?)?.toInt() ?? 0;
          IconData icon = Icons.wb_sunny_rounded;
          if (code == 0 || code == 1) {
            icon = Icons.wb_sunny_rounded;
          } else if (code == 2) {
            icon = Icons.wb_cloudy_rounded;
          } else if (code == 3) {
            icon = Icons.cloud_rounded;
          } else if (code <= 48) {
            icon = Icons.blur_on_rounded; // Fog
          } else if (code <= 55) {
            icon = Icons.grain_rounded; // Drizzle
          } else if (code <= 67 || (code >= 80 && code <= 82)) {
            icon = Icons.beach_access_rounded; // Rain
          } else if (code <= 77 || (code >= 85 && code <= 86)) {
            icon = Icons.ac_unit_rounded; // Snow
          } else if (code >= 95) {
            icon = Icons.thunderstorm_rounded;
          }

          setState(() {
            _temperature = temp;
            _weatherIcon = icon;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchGPSInBackground(
    SalahRepository repo,
    LocationData? saved,
  ) async {
    try {
      if (saved != null && saved.isManual) return;
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String city = 'Lat ${pos.latitude.toStringAsFixed(1)}';
      try {
        final geoRes = await http
            .get(
              Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=10',
              ),
              headers: {'User-Agent': 'Deen360/1.0'},
            )
            .timeout(const Duration(seconds: 8));
        if (geoRes.statusCode == 200) {
          final addr = jsonDecode(geoRes.body)['address'];
          city =
              addr?['city'] ??
              addr?['town'] ??
              addr?['village'] ??
              addr?['county'] ??
              city;
        }
      } catch (_) {}

      await repo.saveUserLocation(
        LocationData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          city: city,
        ),
      );

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

    final fajr = _parseTime(t['Fajr'] as String?, today);
    final sunrise = _parseTime(t['Sunrise'] as String?, today);
    final dhuhr = _parseTime(t['Dhuhr'] as String?, today);
    final asr = _parseTime(t['Asr'] as String?, today);
    final sunset = _parseTime(t['Sunset'] as String?, today);
    final maghrib = _parseTime(t['Maghrib'] as String?, today);
    final isha = _parseTime(t['Isha'] as String?, today);
    final midnight = _parseTime(
      t['Midnight'] as String?,
      today,
      afterTime: isha,
    );
    final tomorrowFajr = fajr.add(const Duration(days: 1));

    if (now.isBefore(fajr)) {
      final midnightToday = _parseTime(t['Midnight'] as String?, today);
      if (now.isBefore(midnightToday)) {
        final diff = midnightToday.difference(now);
        _setHUD(
          'ISHA',
          'Isha Salah',
          'Midnight',
          _fmt12(isha.subtract(const Duration(days: 1))),
          _fmt12(midnightToday),
          _fmt12(midnightToday),
          diff,
        );
        return;
      }
      final diff = fajr.difference(now);
      _setHUD(
        'TAHAJJUD',
        'Last Third of Night',
        'Fajr',
        _fmt12(midnightToday),
        _fmt12(fajr),
        _fmt12(fajr),
        diff,
      );
      return;
    }

    final blocks = <_PrayerBlock>[
      _PrayerBlock(
        'FAJR',
        'Fajr Salah',
        fajr,
        sunrise,
        'Sunrise',
        _fmt12(sunrise),
        true,
      ),
      _PrayerBlock(
        'SUNRISE',
        'Ishraq / Duha',
        sunrise,
        dhuhr,
        'Dhuhr',
        _fmt12(dhuhr),
        false,
      ),
      _PrayerBlock(
        'DHUHR',
        'Dhuhr Salah',
        dhuhr,
        asr,
        'Asr',
        _fmt12(asr),
        true,
      ),
      _PrayerBlock(
        'ASR',
        'Asr Salah',
        asr,
        sunset,
        'Maghrib',
        _fmt12(maghrib),
        true,
      ),
      _PrayerBlock(
        'MAGHRIB',
        'Maghrib Salah',
        maghrib,
        isha,
        'Isha',
        _fmt12(isha),
        true,
      ),
      _PrayerBlock(
        'ISHA',
        'Isha Salah',
        isha,
        midnight,
        'Midnight',
        _fmt12(midnight),
        true,
      ),
      _PrayerBlock(
        'MIDNIGHT',
        'Tahajjud / Qiyam',
        midnight,
        tomorrowFajr,
        'Fajr',
        _fmt12(tomorrowFajr),
        false,
      ),
    ];

    for (final block in blocks) {
      if ((now.isAfter(block.start) || now.isAtSameMomentAs(block.start)) &&
          now.isBefore(block.end)) {
        final diff = block.end.difference(now);
        _setHUD(
          block.name,
          block.label,
          block.nextName,
          _fmt12(block.start),
          _fmt12(block.end),
          block.nextTimeStr,
          diff,
        );
        return;
      }
    }

    _setHUD('--', 'Calculating...', '--', '--', '--', '--', Duration.zero);
  }

  void _setHUD(
    String name,
    String label,
    String nextName,
    String start,
    String end,
    String nextTime,
    Duration diff,
  ) {
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
        _timeRemaining = diff.inSeconds <= 0
            ? '00:00:00'
            : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        child: RefreshIndicator(
          onRefresh: () async {
            await _initData();
          },
          color: context.read<ThemeProvider>().primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildZenHUD(),
                if (_lastBookmark != null) _buildContinueReading(context),
                _buildDailyTracker(context),
                _buildPostStudioCard(context),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, bottom: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.text,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ─────────────── CONTINUE READING ───────────────
  Widget _buildContinueReading(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final b = _lastBookmark!;
    final surahName = b['surahName'] ?? 'Surah ${b["surah"]}';
    final ayah = b['ayah'] ?? 1;
    final total = b['totalAyahs'] ?? 1;
    final progress = (ayah / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: GestureDetector(
        onTap: () => widget.onNavigate('surahContent', {
          'number': b['surah'],
          'ayah': ayah,
        }),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: AppShadows.dynamicSoft(theme.primaryColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CONTINUE READING',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.primaryColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surahName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.text,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ayah $ayah of $total',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSearchSheet(
        primaryColor: context.watch<ThemeProvider>().primaryColor,
        onLocationSelected: (data) => _updateLocation(data),
        onResetToGPS: () => _initData(forceGPS: true),
      ),
    );
  }

  Future<void> _updateLocation(LocationData data) async {
    if (!mounted) return;
    setState(() => _locationName = data.city ?? 'Saved');
    await context.read<SalahRepository>().saveUserLocation(data);
    _fetchTimingsAndWeather(data.latitude, data.longitude);
  }

  // ─────────────── ZEN HUD ──────────────s─
  LinearGradient _getHUDGradient() {
    switch (_currentPrayerName.toUpperCase()) {
      case 'FAJR':
        return AppGradients.fajr;
      case 'SUNRISE':
        return AppGradients.sunrise;
      case 'DHUHR':
        return AppGradients.dhuhr;
      case 'ASR':
        return AppGradients.asr;
      case 'MAGHRIB':
        return AppGradients.maghrib;
      case 'ISHA':
        return AppGradients.isha;
      case 'MIDNIGHT':
        return AppGradients.midnight;
      case 'TAHAJJUD':
      case 'TAHAJJUD_VIGIL':
        return AppGradients.tahajjud;
      default:
        return AppGradients.primary;
    }
  }

  Widget _buildZenHUD() {
    final gradient = _getHUDGradient();
    final isLight = AppGradients.isLightText(_currentPrayerName);
    final foregroundColor = isLight ? Colors.white : AppTheme.text;
    final mutedForegroundColor = isLight
        ? Colors.white.withValues(alpha: 0.75)
        : AppTheme.textMuted;
    final secondaryBgColor = isLight
        ? Colors.white.withValues(alpha: 0.2)
        : AppTheme.text.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: () => widget.onNavigate('salah'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: foregroundColor.withValues(alpha: 0.15)),
          boxShadow: AppShadows.dynamicFloating(
            isLight
                ? context.watch<ThemeProvider>().primaryColor
                : Colors.black,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: _showLocationSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: foregroundColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: foregroundColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _locationName,
                              style: TextStyle(
                                color: foregroundColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: secondaryBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: foregroundColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(_weatherIcon, size: 14, color: foregroundColor),
                      const SizedBox(width: 6),
                      Text(
                        '${_temperature != null ? "$_temperature°C" : "--°C"}',
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
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
                        child: Text(
                          _currentPrayerName,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.08,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentPrayerLabel.isNotEmpty
                            ? _currentPrayerLabel
                            : 'Current Period',
                        style: TextStyle(
                          color: mutedForegroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Until $_nextPrayerName',
                        style: TextStyle(
                          color: mutedForegroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: foregroundColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatItem(
                  'Started',
                  _currentStart,
                  foregroundColor,
                  mutedForegroundColor,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: foregroundColor.withValues(alpha: 0.15),
                ),
                _buildStatItem(
                  'Ending',
                  _currentEnd,
                  foregroundColor,
                  mutedForegroundColor,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: foregroundColor.withValues(alpha: 0.15),
                ),
                _buildStatItem(
                  '$_nextPrayerName at',
                  _nextTime,
                  foregroundColor,
                  mutedForegroundColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color foreground,
    Color mutedForeground,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedForeground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
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
              const Text(
                'Daily Salah Tracker',
                style: TextStyle(
                  color: AppTheme.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              GestureDetector(
                onTap: () => widget.onNavigate('salahCalendar'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress/5',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: AppShadows.dynamicSoft(primaryColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: prayers.map((p) {
                final entry = tracker.getEntry(DateTime.now(), p);
                final isDone =
                    entry.status == SalahStatus.alone ||
                    entry.status == SalahStatus.jamaat ||
                    entry.status == SalahStatus.qaza;
                final isMissed = entry.status == SalahStatus.missed;

                Color ballColor = const Color(0xFFF1F5F9);
                Widget? icon;
                if (isDone) {
                  ballColor = primaryColor;
                  icon = const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  );
                } else if (isMissed) {
                  ballColor = Colors.red.withValues(alpha: 0.1);
                  icon = const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 18,
                  );
                }

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          SalahLogSheet(date: DateTime.now(), prayerName: p),
                    );
                  },
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ballColor,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: icon,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p,
                        style: TextStyle(
                          color: isDone
                              ? primaryColor
                              : (isMissed
                                    ? Colors.red
                                    : const Color(0xFF94A3B8)),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── POST STUDIO ───────────────
  Widget _buildPostStudioCard(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: GestureDetector(
        onTap: () => widget.onNavigate('postStudio'),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            image: const DecorationImage(
              image: NetworkImage(
                'https://loremflickr.com/800/400/nature,mountain',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: AppShadows.dynamicSoft(theme.primaryColor),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'POST STUDIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Post Ayah & Hadith',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Design beautiful nature-themed posts with Ayahs and Hadiths.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
            boxShadow: AppShadows.dynamicFloating(theme.primaryColor),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'DAILY AYAH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.share_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Icon(
                Icons.format_quote_rounded,
                size: 32,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 10),
              const Text(
                '"أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '"Verily, in the remembrance of Allah do hearts find rest."',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Surah Ar-Ra\'d [13:28]',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
  _PrayerBlock(
    this.name,
    this.label,
    this.start,
    this.end,
    this.nextName,
    this.nextTimeStr,
    this.isFard,
  );
}
