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

class SurahScreen extends StatefulWidget {
  final int surahNumber;
  final int? initialAyah;
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const SurahScreen({
    super.key, 
    required this.surahNumber, 
    this.initialAyah,
    required this.onNavigate
  });

  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<Verse> _verses = [];
  bool _loading = true;
  String _surahTitle = '';
  String _surahArabicName = '';
  double _readProgress = 0;
  int? _activeBookmark;
  
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingAyah;
  bool _isPlaying = false;
  bool _isLoadingAudio = false;

  @override
  void initState() {
    super.initState();
    _fetchSurah();
    _loadBookmark();
    
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() { _playingAyah = null; _isPlaying = false; });
        if (_playingAyah != null && _playingAyah! < _verses.length) {
          _playAyah(_playingAyah! + 1);
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

    // Find the last visible item to calculate progress
    final lastIndex = positions.where((p) => p.itemTrailingEdge > 0).map((p) => p.index).reduce((a, b) => a > b ? a : b);
    
    // index 0 is Bismillah, so verses start at 1
    final progress = (lastIndex / _verses.length).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.01) {
      setState(() => _readProgress = progress);
    }
  }

  Future<void> _fetchSurah() async {
    final repo = context.read<QuranRepository>();
    final verses = await repo.loadSurah(widget.surahNumber);
    if (mounted) {
      setState(() {
        _verses = verses;
        _loading = false;
        _surahTitle = 'Surah ${widget.surahNumber}';
      });
      
      // Handle initial jump if provided
      if (widget.initialAyah != null && widget.initialAyah! > 0) {
        // Wait a bit for the list to build
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_itemScrollController.isAttached) {
            _itemScrollController.jumpTo(index: widget.initialAyah!);
          }
        });
      }
    }
    // Get surah meta
    try {
      final url = Uri.parse('https://api.quran.com/api/v4/chapters/${widget.surahNumber}?language=en');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final ch = jsonDecode(res.body)['chapter'];
        if (ch != null && mounted) {
          setState(() {
            _surahTitle = ch['name_simple'] ?? _surahTitle;
            _surahArabicName = ch['name_arabic'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks');
      if (raw != null) {
        final bookmarks = jsonDecode(raw) as List;
        final bk = bookmarks.where((b) => b['surah'] == widget.surahNumber).toList();
        if (bk.isNotEmpty && mounted) {
          setState(() => _activeBookmark = bk.last['ayah']);
        }
      }
    } catch (_) {}
  }

  Future<void> _bookmarkAyah(Verse verse, int ayahNum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('deen360_bookmarks') ?? '[]';
      List bookmarks = jsonDecode(raw);
      bookmarks.removeWhere((b) => b['surah'] == widget.surahNumber);
      bookmarks.add({
        'surah': widget.surahNumber,
        'surahName': _surahTitle,
        'ayah': ayahNum,
        'totalAyahs': _verses.length,
        'date': DateTime.now().toIso8601String(),
      });
      await prefs.setString('deen360_bookmarks', jsonEncode(bookmarks));
      if (mounted) {
        setState(() => _activeBookmark = ayahNum);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmarked $_surahTitle Ayah $ayahNum'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _playAyah(int ayahNum) async {
    if (_playingAyah == ayahNum && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }
    if (_playingAyah == ayahNum && !_isPlaying) {
      await _audioPlayer.resume();
      return;
    }

    setState(() { _playingAyah = ayahNum; _isLoadingAudio = true; });

    try {
      final verseKey = '${widget.surahNumber}:$ayahNum';
      final audioUrl = 'https://api.quran.com/api/v4/recitations/7/by_ayah/$verseKey';
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
        } else {
          final padded = ayahNum.toString().padLeft(3, '0');
          final surahPadded = widget.surahNumber.toString().padLeft(3, '0');
          final directUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$surahPadded$padded.mp3';
          await _audioPlayer.stop();
          await _audioPlayer.play(UrlSource(directUrl));
        }
      } else {
        final globalAyah = _getGlobalAyahNumber(widget.surahNumber, ayahNum);
        final directUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalAyah.mp3';
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(directUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio unavailable. Check your internet connection.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        setState(() { _playingAyah = null; _isPlaying = false; });
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  int _getGlobalAyahNumber(int surah, int ayah) {
    const verseCounts = [0,7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6];
    int total = 0;
    for (int i = 1; i < surah && i < verseCounts.length; i++) {
      total += verseCounts[i];
    }
    return total + ayah;
  }

  void _showShareOptions(Verse verse, int ayahNum) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Share Ayah $ayahNum', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_surahTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              ),
              const SizedBox(height: 24),
              _ShareOption(
                icon: Icons.text_fields_rounded,
                title: 'Share as Text',
                subtitle: 'Arabic + Translation + Reference',
                onTap: () {
                  Navigator.pop(ctx);
                  _shareText(verse, ayahNum);
                },
              ),
              Divider(height: 1, indent: 72, endIndent: 24, color: AppTheme.border),
              _ShareOption(
                icon: Icons.headphones_rounded,
                title: 'Share as Audio',
                subtitle: 'MP3 Recitation — Al-Afasy',
                onTap: () {
                  Navigator.pop(ctx);
                  _shareAudio(verse, ayahNum);
                },
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }

  void _shareText(Verse verse, int ayahNum) {
    final text = '${verse.ar}\n\n"${verse.en}"\n\n— $_surahTitle [$ayahNum]\n\nShared via Deen360';
    Share.share(text);
  }

  Future<File?> _downloadAyahAudio(int ayahNum) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final safeSurahName = _surahTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${safeSurahName}_Ayah_$ayahNum.mp3';
      final file = File('${tempDir.path}/$fileName');

      if (await file.exists() && await file.length() > 1000) {
        return file;
      }

      String? audioUrl;
      final verseKey = '${widget.surahNumber}:$ayahNum';
      final apiUrl = 'https://api.quran.com/api/v4/recitations/7/by_ayah/$verseKey';
      
      final res = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final audioFiles = data['audio_files'] as List?;
        if (audioFiles != null && audioFiles.isNotEmpty) {
          String url = audioFiles[0]['url'] ?? '';
          if (url.startsWith('//')) url = 'https:$url';
          if (!url.startsWith('http')) url = 'https://verses.quran.com/$url';
          audioUrl = url;
        }
      }

      audioUrl ??= 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${_getGlobalAyahNumber(widget.surahNumber, ayahNum)}.mp3';

      final audioRes = await http.get(Uri.parse(audioUrl)).timeout(const Duration(seconds: 20));
      if (audioRes.statusCode != 200) return null;

      await file.writeAsBytes(audioRes.bodyBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _shareAudio(Verse verse, int ayahNum) async {
    _showDownloadSnackbar();
    final file = await _downloadAyahAudio(ayahNum);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'audio/mpeg')],
        subject: 'Ayah Recitation: $_surahTitle [$ayahNum]',
      );
    } else {
      _showErrorSnackbar();
    }
  }

  void _showDownloadSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Downloading recitation...'),
        ]),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 15),
      ),
    );
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Failed to download audio. Check your connection.'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _audioPlayer.stop();
                          widget.onNavigate('surahList');
                        },
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                          child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(_surahTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                            Text('${_verses.length} VERSES', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _playAyah(1),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _isPlaying ? AppTheme.primary : AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 22,
                            color: _isPlaying ? Colors.white : context.watch<ThemeProvider>().primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 4, width: double.infinity, color: const Color(0xFFF1F5F9),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _readProgress,
                    child: Container(color: context.watch<ThemeProvider>().primaryColor),
                  ),
                ),
              ],
            ),
          ),

          if (_playingAyah != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.06),
              child: Row(
                children: [
                  if (_isLoadingAudio)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                  else
                     Icon(Icons.graphic_eq_rounded, size: 20, color: context.watch<ThemeProvider>().primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Playing Ayah $_playingAyah • $_surahTitle',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: context.watch<ThemeProvider>().primaryColor),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await _audioPlayer.stop();
                      setState(() { _playingAyah = null; _isPlaying = false; });
                    },
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child:  Icon(Icons.close_rounded, size: 16, color: context.watch<ThemeProvider>().primaryColor),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loading
              ?  Center(child: CircularProgressIndicator(color: context.read<ThemeProvider>().primaryColor))
              : ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _verses.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == 0) return _buildBismillahHero();
                    final verse = _verses[index - 1];
                    return _buildAyahRow(verse, index - 1);
                  },
                ),
          ),
        ],
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
          boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            if (_surahArabicName.isNotEmpty)
              Text(_surahArabicName, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16, fontWeight: FontWeight.w800)),
            if (_surahArabicName.isNotEmpty) const SizedBox(height: 8),
            const Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.8), textAlign: TextAlign.center),
            Container(width: 40, height: 3, margin: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            Text('Begin in the Name of Allah', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahRow(Verse verse, int index) {
    final ayahNum = int.tryParse(verse.ayah.split(':').last) ?? (index + 1);
    final isBookmarked = _activeBookmark == ayahNum;
    final isCurrentlyPlaying = _playingAyah == ayahNum;

    return Container(
      color: isCurrentlyPlaying ? context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.04) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text('$ayahNum', style: TextStyle(color: context.watch<ThemeProvider>().primaryColor, fontWeight: FontWeight.w900, fontSize: 14))),
                ),
                Row(
                  children: [
                    _ActionBtn(
                      icon: isCurrentlyPlaying && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      isActive: isCurrentlyPlaying,
                      isLoading: isCurrentlyPlaying && _isLoadingAudio,
                      onTap: () => _playAyah(ayahNum),
                    ),
                    const SizedBox(width: 10),
                    _ActionBtn(
                      icon: Icons.share_rounded,
                      onTap: () => _showShareOptions(verse, ayahNum),
                    ),
                    const SizedBox(width: 10),
                    _ActionBtn(
                      icon: Icons.bookmark_rounded,
                      isActive: isBookmarked,
                      onTap: () => _bookmarkAyah(verse, ayahNum),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(verse.ar, style: const TextStyle(fontSize: 28, color: AppTheme.text, height: 2, fontWeight: FontWeight.w400), textAlign: TextAlign.right),
            const SizedBox(height: 20),
            Text(verse.en, style: const TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.75, fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            Container(height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 10), color: const Color(0xFFF1F5F9)),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;
  const _ActionBtn({required this.icon, required this.onTap, this.isActive = false, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isActive ? context.watch<ThemeProvider>().primaryColor : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 16, color: isActive ? Colors.white : AppTheme.text),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ShareOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: context.watch<ThemeProvider>().primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20, color: context.watch<ThemeProvider>().primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.text)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
