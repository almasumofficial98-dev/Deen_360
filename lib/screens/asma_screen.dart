import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/asma_repository.dart';

class AsmaScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const AsmaScreen({super.key, required this.onNavigate});

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  List<AsmaName> _names = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final repo = context.read<AsmaRepository>();
    final data = await repo.loadAsmaUlHusna();
    if (mounted) setState(() { _names = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildNameGridItem(_names[i], i),
                      childCount: _names.length,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => widget.onNavigate('home'),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Icon(Icons.arrow_back_rounded, color: AppTheme.text, size: 20)),
                ),
              ),
              const Expanded(
                child: Column(
                  children: [
                    Text('Asma-Ul-Husna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
                    SizedBox(height: 2),
                    Text('The 99 Beautiful Names', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppShadows.floating,
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('ATTRIBUTES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
                const SizedBox(height: 16),
                const Text('99 Names of Allah', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('A guide to the divine nature.', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameGridItem(AsmaName name, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text((index + 1).toString().padLeft(2, '0'), 
            style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w900)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name.name, style: const TextStyle(fontSize: 28, color: AppTheme.text, fontWeight: FontWeight.w600, height: 1.4)),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name.transliteration, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.text)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(name.meaning, maxLines: 1, style: const TextStyle(fontSize: 10, color: AppTheme.textLight, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
