import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/quran_repository.dart';

enum ReadingMode { surah, juz }

class SurahScreen extends StatefulWidget {
  final int id; // surahNumber or juzNumber
  final ReadingMode mode;
  final int? initialAyah;
  final Function(String, [Map<String, dynamic>?]) onNavigate;

  const SurahScreen({
    super.key,
    required this.id,
    this.mode = ReadingMode.surah,
    this.initialAyah,
    required this.onNavigate,
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Verse> _verses = [];
  bool _loading = true;
  bool _isSharing = false;
  String _title = '';
  String _arabicName = '';
  double _readProgress = 0.0;
  int? _activeBookmark;
  String _currentLang = 'en';
  Map<int, String> _surahNames = {};

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingAyahIndex;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadBookmark();

    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        if (_playingAyahIndex != null &&
            _playingAyahIndex! < _verses.length - 1) {
          _playAyahByIndex(_playingAyahIndex! + 1);
        } else {
          setState(() {
            _playingAyahIndex = null;
            _isPlaying = false;
          });
        }
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    if (_verses.isEmpty) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final lastIndex = positions
        .where((p) => p.itemTrailingEdge > 0)
        .map((p) => p.index)
        .reduce((a, b) => a > b ? a : b);
    final progress = (lastIndex / _verses.length).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.01) {
      setState(() => _readProgress = progress);
    }
  }

  Future<void> _fetchData() async {
    if (mounted && _verses.isNotEmpty) {
      setState(() => _loading = true);
    }

    final repo = context.read<QuranRepository>();
    List<Verse> verses;

    if (widget.mode == ReadingMode.surah) {
      verses = await repo.loadSurah(widget.id, language: _currentLang);
    } else {
      verses = await repo.loadJuz(widget.id, language: _currentLang);
      await _fetchSurahNames();
    }

    if (mounted) {
      setState(() {
        _verses = verses;
        _loading = false;
        _title = widget.mode == ReadingMode.surah
            ? 'Surah ${widget.id}'
            : 'Para ${widget.id}';
      });

      if (widget.initialAyah != null && widget.initialAyah! > 0) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_itemScrollController.isAttached) {
            _itemScrollController.jumpTo(index: widget.initialAyah!);
          }
        });
      }
    }

    if (widget.mode == ReadingMode.surah) {
      _fetchSurahMeta();
    }
  }

  Future<void> _fetchSurahNames() async {
    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/chapters?language=en',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final chapters = jsonDecode(res.body)['chapters'] as List;
        Map<int, String> names = {};
        for (var ch in chapters) {
          names[ch['id']] = ch['name_simple'] ?? 'Surah ${ch['id']}';
        }
        if (mounted) setState(() => _surahNames = names);
      }
    } catch (_) {}
  }

  Future<void> _fetchSurahMeta() async {
    try {
      final url = Uri.parse(
        'https://api.quran.com/api/v4/chapters/${widget.id}?language=en',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final ch = jsonDecode(res.body)['chapter'];
        if (ch != null && mounted) {
          setState(() {
            _title = ch['name_simple'] ?? _title;
            _arabicName = ch['name_arabic'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBookmark() async {
    if (widget.mode != ReadingMode.surah) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks');
      if (raw != null) {
        final bookmarks = jsonDecode(raw) as List;
        final bk = bookmarks.where((b) => b['surah'] == widget.id).toList();
        if (bk.isNotEmpty && mounted) {
          setState(() => _activeBookmark = bk.last['ayah']);
        }
      }
    } catch (_) {}
  }

  Future<void> _playAyahByIndex(int index) async {
    if (index < 0 || index >= _verses.length) return;
    final verse = _verses[index];
    final parts = verse.id.split(':');
    final sNum = (int.tryParse(parts[0]) ?? 1);
    final aNum = (int.tryParse(parts[1]) ?? 1);

    if (_playingAyahIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }
    if (_playingAyahIndex == index && !_isPlaying) {
      await _audioPlayer.resume();
      return;
    }

    setState(() {
      _playingAyahIndex = index;
      _isLoadingAudio = true;
    });

    try {
      final verseKey = '$sNum:$aNum';
      final audioUrl =
          'https://api.quran.com/api/v4/recitations/7/by_ayah/$verseKey';
      final res = await http.get(Uri.parse(audioUrl));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final audioFiles = data['audio_files'] as List?;

        if (audioFiles != null && audioFiles.isNotEmpty) {
          String url = audioFiles[0]['url'] ?? '';
          if (url.startsWith('//')) url = 'https:$url';
          if (!url.startsWith('http')) url = 'https://verses.quran.com/$url';
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(url));
          return;
        }
      }

      // Fallback
      final globalAyah = _getGlobalAyahNumber(sNum, aNum);
      final directUrl =
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(directUrl));
    } catch (e) {
      if (mounted) _showErrorToast('Audio unavailable');
      setState(() {
        _playingAyahIndex = null;
        _isPlaying = false;
      });
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _showErrorToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _getGlobalAyahNumber(int surah, int ayah) {
    const counts = [
      0,
      7,
      286,
      200,
      176,
      120,
      165,
      206,
      75,
      129,
      109,
      123,
      111,
      43,
      52,
      99,
      128,
      111,
      110,
      98,
      135,
      112,
      78,
      118,
      64,
      77,
      227,
      93,
      88,
      69,
      60,
      34,
      30,
      73,
      54,
      45,
      83,
      182,
      88,
      75,
      85,
      54,
      53,
      89,
      59,
      37,
      35,
      38,
      29,
      18,
      45,
      60,
      49,
      62,
      55,
      78,
      96,
      29,
      22,
      24,
      13,
      14,
      11,
      11,
      18,
      12,
      12,
      30,
      52,
      52,
      44,
      28,
      28,
      20,
      56,
      40,
      31,
      50,
      40,
      46,
      42,
      29,
      19,
      36,
      25,
      22,
      17,
      19,
      26,
      30,
      20,
      15,
      21,
      11,
      8,
      8,
      19,
      5,
      8,
      8,
      11,
      11,
      8,
      3,
      9,
      5,
      4,
      7,
      3,
      6,
      3,
      5,
      4,
      5,
      6,
    ];
    int total = 0;
    for (int i = 1; i < surah && i < counts.length; i++) total += counts[i];
    return total + ayah;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _audioPlayer.stop();
                          widget.onNavigate('pop');
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_rounded,
                              size: 20,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.text,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              widget.mode == ReadingMode.surah
                                  ? '${_verses.length} VERSES'
                                  : 'PARA ${widget.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _playAyahByIndex(0),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isPlaying
                                ? AppTheme.primary
                                : AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 22,
                            color: _isPlaying
                                ? Colors.white
                                : theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLanguageSelector(),
                _buildTeluguWarning(),
                Container(
                  height: 4,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _readProgress,
                    child: Container(color: theme.primaryColor),
                  ),
                ),
              ],
            ),
          ),

          if (_playingAyahIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: theme.primaryColor.withOpacity(0.06),
              child: Row(
                children: [
                  if (_isLoadingAudio)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 20,
                      color: theme.primaryColor,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Playing: ${_verses[_playingAyahIndex!].id} • $_title',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _audioPlayer.stop();
                      setState(() {
                        _playingAyahIndex = null;
                        _isPlaying = false;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  )
                : ScrollablePositionedList.builder(
                    itemScrollController: _itemScrollController,
                    itemPositionsListener: _itemPositionsListener,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount:
                        _verses.length +
                        (widget.mode == ReadingMode.surah ? 1 : 0) +
                        1, // +1 for attribution footer
                    itemBuilder: (ctx, index) {
                      if (index ==
                          _verses.length +
                              (widget.mode == ReadingMode.surah ? 1 : 0)) {
                        return _buildAttributionFooter();
                      }
                      if (widget.mode == ReadingMode.surah) {
                        if (index == 0) return _buildBismillahHero();
                        return _buildAyahRow(_verses[index - 1], index - 1);
                      } else {
                        return _buildJuzAyahRow(index);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeluguWarning() {
    if (_currentLang != 'te') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Telugu translation not available yet',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Falling back to English (Sahih International)',
                  style: TextStyle(
                    color: AppTheme.error.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributionFooter() {
    final repo = context.read<QuranRepository>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(width: 40, height: 1, color: AppTheme.border),
          const SizedBox(height: 16),
          Text(
            repo.getAttribution(_currentLang),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Text sourced from AlQuran Cloud and QuranEnc',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    final theme = context.watch<ThemeProvider>();
    final langs = [
      {'code': 'en', 'label': 'English'},
      {'code': 'ur', 'label': 'Urdu'},
      {'code': 'hi', 'label': 'Hindi'},
      {'code': 'bn', 'label': 'Bengali'},
      {'code': 'te', 'label': 'Telugu'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: langs.length,
        itemBuilder: (context, index) {
          final lang = langs[index];
          final isSelected = _currentLang == lang['code'];
          return GestureDetector(
            onTap: () {
              if (!isSelected) {
                setState(() => _currentLang = lang['code']!);
                _fetchData();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.primaryColor : AppTheme.border,
                ),
              ),
              child: Center(
                child: Text(
                  lang['label']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBismillahHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.watch<ThemeProvider>().activeGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppShadows.dynamicFloating(
            context.watch<ThemeProvider>().primaryColor,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            if (_arabicName.isNotEmpty)
              Text(
                _arabicName,
                style: AppTypography.arabic(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            if (_arabicName.isNotEmpty) const SizedBox(height: 8),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              style: AppTypography.arabic(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ).copyWith(height: 1.8),
              textAlign: TextAlign.center,
            ),
            if (widget.mode == ReadingMode.surah) ...[
              Container(
                width: 40,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Begin in the Name of Allah',
                style: AppTheme.body.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJuzAyahRow(int index) {
    final verse = _verses[index];
    final parts = verse.id.split(':');
    final sNum = (int.tryParse(parts[0]) ?? 1);
    final aNum = (int.tryParse(parts[1]) ?? 1);

    bool showSurahHeader = false;
    if (index == 0) {
      showSurahHeader = true;
    } else {
      final prevParts = _verses[index - 1].id.split(':');
      final prevSNum = prevParts.isNotEmpty
          ? (int.tryParse(prevParts[0]) ?? 0)
          : 0;
      if (prevSNum != sNum) {
        showSurahHeader = true;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSurahHeader) ...[
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: AppTheme.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'SURAH ${_surahNames[sNum] ?? "#$sNum"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Beginning of Chapter',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container(height: 1, color: AppTheme.border)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (sNum != 1 && sNum != 9) _buildBismillahSmall(),
        ],
        _buildAyahRow(verse, index),
      ],
    );
  }

  Widget _buildBismillahSmall() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          style: AppTypography.arabic(
            color: AppTheme.textLight,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildAyahRow(Verse verse, int index) {
    final parts = verse.id.split(':');
    if (parts.length < 2) return const SizedBox.shrink();
    final sNum = int.tryParse(parts[0]) ?? 1;
    final aNum = int.tryParse(parts[1]) ?? 1;
    final isBookmarked =
        widget.mode == ReadingMode.surah && _activeBookmark == aNum;
    final isCurrentlyPlaying = _playingAyahIndex == index;
    final theme = context.watch<ThemeProvider>();

    return Container(
      color: isCurrentlyPlaying
          ? theme.primaryColor.withOpacity(0.04)
          : Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '$sNum:$aNum',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _ActionBtn(
                          icon: isCurrentlyPlaying && _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          isActive: isCurrentlyPlaying,
                          isLoading: isCurrentlyPlaying && _isLoadingAudio,
                          onTap: () => _playAyahByIndex(index),
                        ),
                        const SizedBox(width: 10),
                        _ActionBtn(
                          icon: Icons.share_rounded,
                          isLoading: _isSharing,
                          onTap: () => _showShareOptions(verse, sNum, aNum),
                        ),
                        if (widget.mode == ReadingMode.surah) ...[
                          const SizedBox(width: 10),
                          _ActionBtn(
                            icon: Icons.bookmark_rounded,
                            isActive: isBookmarked,
                            onTap: () => _bookmarkAyah(verse, aNum),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  verse.ar,
                  style: AppTypography.arabic(
                    fontSize: 28,
                    color: AppTheme.text,
                    fontWeight: FontWeight.w400,
                  ).copyWith(height: 1.8),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                Text(
                  verse.translation,
                  style: AppTypography.getStyleByLang(
                    _currentLang == 'te' ? 'en' : _currentLang,
                    fontSize: 16,
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ).copyWith(height: 1.75),
                ),
              ],
            ),
          ),
          _buildSeparator(),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    final theme = context.watch<ThemeProvider>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 1,
            color: AppTheme.border.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: theme.primaryColor.withOpacity(0.2),
            ),
          ),
          Container(
            width: 40,
            height: 1,
            color: AppTheme.border.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Future<void> _bookmarkAyah(Verse verse, int ayahNum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks') ?? '[]';
      List bookmarks = jsonDecode(raw);
      bookmarks.removeWhere((b) => b['surah'] == widget.id);
      bookmarks.add({
        'surah': widget.id,
        'surahName': _title,
        'ayah': ayahNum,
        'totalAyahs': _verses.length,
        'date': DateTime.now().toIso8601String(),
      });
      await prefs.setString('deen360_bookmarks', jsonEncode(bookmarks));
      if (mounted) setState(() => _activeBookmark = ayahNum);
    } catch (_) {}
  }

  void _showShareOptions(Verse verse, int sNum, int aNum) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Share Ayah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Surah ${_surahNames[sNum] ?? "#$sNum"} • Ayah $aNum',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.text_fields_rounded,
                    label: 'Text',
                    onTap: () {
                      Navigator.pop(context);
                      _shareText(verse, sNum, aNum);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildShareOption(
                    icon: Icons.mic_none_rounded,
                    label: 'Recitation',
                    onTap: () {
                      Navigator.pop(context);
                      _shareRecitation(verse, sNum, aNum);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareText(Verse verse, int sNum, int aNum) {
    final surahName = _surahNames[sNum] ?? 'Surah $sNum';
    final attribution = context.read<QuranRepository>().getAttribution(
      _currentLang,
    );
    final text =
        '${verse.ar}\n\n"${verse.translation}"\n\n— $surahName [$aNum]\n\n$attribution\nShared via Deen360';
    Share.share(text);
  }

  Future<void> _shareRecitation(Verse verse, int sNum, int aNum) async {
    setState(() => _isSharing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing recitation...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final verseKey = '$sNum:$aNum';
      String? audioUrl;

      // 1. Try to get URL (similar to playback)
      final res = await http.get(
        Uri.parse(
          'https://api.quran.com/api/v4/recitations/7/by_ayah/$verseKey',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final audioFiles = data['audio_files'] as List?;
        if (audioFiles != null && audioFiles.isNotEmpty) {
          audioUrl = audioFiles[0]['url'] ?? '';
          if (audioUrl!.startsWith('//')) audioUrl = 'https:$audioUrl';
          if (!audioUrl.startsWith('http')) {
            audioUrl = 'https://verses.quran.com/$audioUrl';
          }
        }
      }

      if (audioUrl == null) {
        final globalAyah = _getGlobalAyahNumber(sNum, aNum);
        audioUrl =
            'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';
      }

      // 2. Download to temp file
      final response = await http.get(Uri.parse(audioUrl!));
      final tempDir = await getTemporaryDirectory();
      final surahName = (_surahNames[sNum] ?? 'Surah_$sNum').replaceAll(
        ' ',
        '_',
      );
      final fileName = '${surahName}_$aNum.mp3';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      // 3. Share using shareXFiles
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Ayah $sNum:$aNum Recitation\nShared via Deen360');
    } catch (e) {
      if (mounted) _showErrorToast('Failed to share recitation');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;
  const _ActionBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive
              ? context.watch<ThemeProvider>().primaryColor
              : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: isActive ? Colors.white : AppTheme.text,
              ),
      ),
    );
  }
}
