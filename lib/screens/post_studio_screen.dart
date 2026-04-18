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
  bool _useGradient = false;
  int _gradientIndex = 0;

  // Curated list of high-quality nature images with NO HUMANS or ANIMALS (Verified Unsplash IDs)
  static const List<String> _curatedNaturePool = [
    'https://images.unsplash.com/photo-1501854140801-50d01698950b', // Mountain
    'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05', // Forest fog
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e', // Sunlight forest
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b', // Mountain range
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e', // Green hills
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef', // Single tree hills
    'https://images.unsplash.com/photo-1433086966358-54859d0ee716', // Waterfall
    'https://images.unsplash.com/photo-1426604966144-86bbecf20c19', // Mountains & lake
    'https://images.unsplash.com/photo-1497436072909-60f360e1d4b1', // Blue lake
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb', // Canyon
    'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a', // Stars/Dark sky
    'https://images.unsplash.com/photo-1505144808419-1957a94ca61e', // Tropical sea
    'https://images.unsplash.com/photo-1439853949127-fa647821eba0', // Ocean wave
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23', // Clouds
    'https://images.unsplash.com/photo-1469474099711-44760acc872c', // Desert canyon
    'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d', // River forest
  ];

  static const List<LinearGradient> _spiritualGradients = [
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF064E3B), Color(0xFF065F46)]), // Emerald
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF)]), // Royal Blue
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF581C87), Color(0xFF701A75)]), // Mystical Purple
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF78350F), Color(0xFF92400E)]), // Desert Sand
    LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F172A), Color(0xFF1E293B)]), // Midnight
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _inputText = widget.initialText ?? "Verily, with hardship comes ease.";
    _inputSource = widget.initialSource ?? "Surah Ash-Sharh [94:6]";
    _updateImageUrl();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _updateImageUrl() {
    setState(() {
      final random = Random();
      final base = _curatedNaturePool[random.nextInt(_curatedNaturePool.length)];
      _currentImageUrl = "$base?auto=format&fit=crop&w=1080&q=80";
    });
  }

  void _toggleBackgroundMode() {
    setState(() {
      if (_useGradient) {
        _gradientIndex = (_gradientIndex + 1) % _spiritualGradients.length;
        if (_gradientIndex == 0) _useGradient = false; // Back to image
      } else {
        _useGradient = true;
        _gradientIndex = 0;
      }
    });
  }

  Future<void> _sharePost() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw "Capture area error";
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      
      if (pngBytes != null && mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/deen360_post_${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);
        if (!mounted) return;
        await Share.shareXFiles([XFile(file.path)], text: 'Created with Deen360 Post Studio');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showTextEditor() {
    final tC = TextEditingController(text: _inputText);
    final sC = TextEditingController(text: _inputSource);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16), padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Custom Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
          const SizedBox(height: 16),
          TextField(controller: tC, maxLines: 4, decoration: InputDecoration(filled: true, fillColor: AppTheme.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          TextField(controller: sC, decoration: InputDecoration(hintText: 'Source', filled: true, fillColor: AppTheme.inputBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { setState(() { _inputText = tC.text; _inputSource = sC.text; }); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: context.read<ThemeProvider>().primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.w800)),
          )),
        ]),
      ),
    );
  }

  Future<void> _showQuranPicker() async {
    final qRepo = context.read<QuranRepository>();
    final surah = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPickerModal(title: 'Select Surah', items: List.generate(114, (i) => {'index': i + 1, 'name': 'Surah ${i + 1}'}), itemBuilder: (item) => ListTile(title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(ctx, item)))
    );
    if (surah == null) return;
    setState(() => _isLoadingContent = true);
    try {
      final verses = await qRepo.loadSurah(surah['index']);
      if (!mounted) return;
      setState(() => _isLoadingContent = false);
      final v = await showModalBottomSheet<Verse>(
        context: context, backgroundColor: Colors.transparent,
        builder: (ctx) => _buildPickerModal(title: 'Select Ayah', items: verses, itemBuilder: (v) => ListTile(title: Text(v.en, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('Ayah ${v.ayah}', style: const TextStyle(fontWeight: FontWeight.w800)), onTap: () => Navigator.pop(ctx, v)))
      );
      if (v != null) setState(() { _inputText = v.en; _inputSource = "Surah ${surah['index']}:${v.ayah}"; });
    } catch (_) { setState(() => _isLoadingContent = false); }
  }

  Future<void> _showHadithPicker() async {
    final hRepo = context.read<HadithRepository>();
    final col = await showModalBottomSheet<HadithCollection>(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPickerModal(title: 'Select Collection', items: HadithRepository.collections, itemBuilder: (c) => ListTile(title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(ctx, c)))
    );
    if (col == null) return;
    setState(() => _isLoadingContent = true);
    try {
      final caps = await hRepo.loadHadithChapters(col.id);
      final cap = caps[Random().nextInt(caps.length)];
      final hadiths = await hRepo.loadHadiths(col.id, cap.id);
      if (!mounted) return;
      setState(() => _isLoadingContent = false);
      if (hadiths.isNotEmpty) {
        final h = hadiths[Random().nextInt(hadiths.length)];
        setState(() { _inputText = h.en; _inputSource = "${col.title} - ${cap.title}"; });
      }
    } catch (_) { setState(() => _isLoadingContent = false); }
  }

  Widget _buildPickerModal({required String title, required List items, required Widget Function(dynamic) itemBuilder}) {
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)), const Spacer(), const Icon(Icons.keyboard_arrow_down_rounded)])),
        const SizedBox(height: 16),
        Flexible(child: ListView.builder(shrinkWrap: true, itemCount: items.length, itemBuilder: (ctx, idx) => itemBuilder(items[idx]))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (didPop) return; widget.onNavigate('home'); },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      image: _useGradient ? null : DecorationImage(image: NetworkImage(_currentImageUrl), fit: BoxFit.cover),
                      gradient: _useGradient ? _spiritualGradients[_gradientIndex] : null,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: _useGradient ? 0.2 : _overlayOpacity)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 40),
                          const SizedBox(height: 20),
                          Text(_inputText, textAlign: _textAlign, style: TextStyle(color: _textColor, fontSize: _fontSize, fontWeight: FontWeight.w800, height: 1.4, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))])),
                          const SizedBox(height: 24),
                          Container(width: 40, height: 2, color: Colors.white38),
                          const SizedBox(height: 24),
                          Text(_inputSource.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          const SizedBox(height: 60),
                          Opacity(opacity: 0.6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 1.5)), child: const Text('DEEN 360', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    _CircleIconButton(icon: Icons.close_rounded, onTap: () => widget.onNavigate('home'), color: Colors.black45),
                    const Text('POST STUDIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                    Row(children: [
                      _CircleIconButton(icon: _useGradient ? Icons.palette_rounded : Icons.refresh_rounded, onTap: _useGradient ? _toggleBackgroundMode : _updateImageUrl, color: Colors.black45),
                      const SizedBox(width: 10),
                      _CircleIconButton(icon: Icons.share_rounded, onTap: _sharePost, color: primaryColor),
                    ]),
                  ]),
                ),
                if (_isLoadingContent) const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.white),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30)]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _ToolBtn(icon: Icons.menu_book_rounded, label: 'Quran', onTap: _showQuranPicker),
                      _ToolBtn(icon: Icons.auto_stories_rounded, label: 'Hadith', onTap: _showHadithPicker),
                      _ToolBtn(icon: Icons.edit_note_rounded, label: 'Edit', onTap: _showTextEditor),
                      _ToolBtn(icon: _useGradient ? Icons.landscape_rounded : Icons.palette_rounded, label: _useGradient ? 'Image' : 'Gradient', onTap: _toggleBackgroundMode),
                      _ToolBtn(icon: Icons.format_size_rounded, label: 'Size', onTap: () => setState(() => _fontSize = (_fontSize > 32) ? 18 : _fontSize + 4)),
                    ]),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        onPressed: _isExporting ? null : _sharePost,
                        icon: _isExporting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.share_rounded, size: 18),
                        label: Text(_isExporting ? 'GENERATING...' : 'SAVE & SHARE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                      )),
                    ]),
                  ]),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final Color color;
  const _CircleIconButton({required this.icon, required this.onTap, required this.color});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Container(width: 48, height: 48, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 22)));
}

class _ToolBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.text, size: 20)),
    const SizedBox(height: 6),
    Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textLight)),
  ]));
}
