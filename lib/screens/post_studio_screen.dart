import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/quran_repository.dart';
import '../data/hadith_repository.dart';

class PostStudioScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  final String? initialText;
  final String? initialSource;

  const PostStudioScreen({
    super.key, 
    required this.onNavigate,
    this.initialText,
    this.initialSource,
  });

  @override
  State<PostStudioScreen> createState() => _PostStudioScreenState();
}

class _PostStudioScreenState extends State<PostStudioScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  late String _currentImageUrl;
  late String _inputText;
  late String _inputSource;
  
  double _fontSize = 24.0;
  TextAlign _textAlign = TextAlign.center;
  double _overlayOpacity = 0.4;
  Color _textColor = Colors.white;
  
  bool _isExporting = false;
  bool _isLoadingContent = false;
  int _imageSeed = 0;

  @override
  void initState() {
    super.initState();
    _inputText = widget.initialText ?? "Verily, with hardship comes ease.";
    _inputSource = widget.initialSource ?? "Surah Ash-Sharh [94:6]";
    _updateImageUrl();
  }

  void _updateImageUrl() {
    setState(() {
      _imageSeed = DateTime.now().millisecondsSinceEpoch;
      _currentImageUrl = "https://loremflickr.com/1080/1920/nature,scenery,landscape?lock=$_imageSeed";
    });
  }

  Future<void> _sharePost() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception("Capture area not found");
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      
      if (pngBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/deen360_post_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Design created with Deen360 Post Studio',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing post: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showTextEditor() {
    final textController = TextEditingController(text: _inputText);
    final sourceController = TextEditingController(text: _inputSource);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Custom Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter Verse or Hadith...',
                filled: true,
                fillColor: AppTheme.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              decoration: InputDecoration(
                hintText: 'Source (e.g. Surah 2:255)',
                filled: true,
                fillColor: AppTheme.inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _inputText = textController.text;
                        _inputSource = sourceController.text;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.read<ThemeProvider>().primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showQuranPicker() async {
    final quranRepo = context.read<QuranRepository>();
    
    // 1. Show Surah Picker
    final surah = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPickerModal(
        title: 'Select Surah',
        items: List.generate(114, (i) => {'index': i + 1, 'name': 'Surah ${i + 1}'}),
        itemBuilder: (item) => ListTile(
          title: Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.pop(ctx, item),
        ),
      ),
    );

    if (surah == null) return;
    final surahNum = surah['index'] as int;

    // 2. Show Ayah Picker
    setState(() => _isLoadingContent = true);
    try {
      final verses = await quranRepo.loadSurah(surahNum);
      if (!mounted) return;
      setState(() => _isLoadingContent = false);

      final selectedVerse = await showModalBottomSheet<Verse>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _buildPickerModal(
          title: 'Select Ayah from Surah $surahNum',
          items: verses,
          itemBuilder: (v) => ListTile(
            title: Text(v.en, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
            subtitle: Text('Ayah ${v.ayah}', style: const TextStyle(fontWeight: FontWeight.w800)),
            onTap: () => Navigator.pop(ctx, v),
          ),
        ),
      );

      if (selectedVerse != null) {
        setState(() {
          _inputText = selectedVerse.en;
          _inputSource = "Surah ${selectedVerse.ayah}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingContent = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading verses: $e')));
    }
  }

  Future<void> _showHadithPicker() async {
    final hadithRepo = context.read<HadithRepository>();
    
    // 1. Show Collection Picker
    final collection = await showModalBottomSheet<HadithCollection>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPickerModal(
        title: 'Select Collection',
        items: HadithRepository.collections,
        itemBuilder: (c) => ListTile(
          leading: Container(width: 8, height: 40, decoration: BoxDecoration(color: Color(int.parse(c.dark.replaceAll('#', '0xFF'))), borderRadius: BorderRadius.circular(4))),
          title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(c.author),
          onTap: () => Navigator.pop(ctx, c),
        ),
      ),
    );

    if (collection == null) return;

    // 2. Pick Random Hadith from collection
    setState(() => _isLoadingContent = true);
    try {
      final chapters = await hadithRepo.loadHadithChapters(collection.id);
      if (chapters.isEmpty) throw "Could not load collection";
      
      final randomChapter = chapters[Random().nextInt(chapters.length)];
      final hadiths = await hadithRepo.loadHadiths(collection.id, randomChapter.id);
      
      if (!mounted) return;
      setState(() => _isLoadingContent = false);

      if (hadiths.isNotEmpty) {
        final h = hadiths[Random().nextInt(hadiths.length)];
        setState(() {
          _inputText = h.en;
          _inputSource = "${collection.title} - ${randomChapter.title}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingContent = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading hadith: $e')));
    }
  }

  Widget _buildPickerModal({required String title, required List items, required Widget Function(dynamic) itemBuilder}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textLight),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (ctx, idx) => itemBuilder(items[idx]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Capturable Area
          Center(
            child: RepaintBoundary(
              key: _boundaryKey,
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    image: DecorationImage(image: NetworkImage(_currentImageUrl), fit: BoxFit.cover),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: _overlayOpacity)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 40),
                        const SizedBox(height: 20),
                        Text(
                          _inputText,
                          textAlign: _textAlign,
                          style: TextStyle(
                            color: _textColor, fontSize: _fontSize, fontWeight: FontWeight.w800, height: 1.4,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(width: 40, height: 2, color: Colors.white38),
                        const SizedBox(height: 24),
                        Text(_inputSource.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 60),
                        Opacity(
                          opacity: 0.6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5)),
                            child: const Text('DEEN 360', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Non-Capturable Controls
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(icon: Icons.close_rounded, onTap: () => widget.onNavigate('home'), color: Colors.black45),
                      const Text('POST STUDIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                      Row(
                        children: [
                          _CircleIconButton(icon: Icons.refresh_rounded, onTap: _updateImageUrl, color: Colors.black45),
                          const SizedBox(width: 10),
                          _CircleIconButton(icon: Icons.share_rounded, onTap: _sharePost, color: primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isLoadingContent)
                  const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.white),
                const Spacer(),
                
                // Bottom UI
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30)]),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ToolBtn(icon: Icons.menu_book_rounded, label: 'Quran', onTap: _showQuranPicker),
                          _ToolBtn(icon: Icons.auto_stories_rounded, label: 'Hadith', onTap: _showHadithPicker),
                          _ToolBtn(icon: Icons.edit_note_rounded, label: 'Edit', onTap: _showTextEditor),
                          _ToolBtn(icon: Icons.format_size_rounded, label: 'Size', 
                            onTap: () => setState(() => _fontSize = (_fontSize > 32) ? 18 : _fontSize + 4)
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _sharePost,
                              icon: _isExporting 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.share_rounded, size: 18),
                              label: Text(_isExporting ? 'GENERATING...' : 'SAVE & SHARE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleIconButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.text, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textLight)),
        ],
      ),
    );
  }
}
