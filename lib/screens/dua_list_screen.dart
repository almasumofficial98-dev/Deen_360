import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/dua_repository.dart';

class DuaListScreen extends StatelessWidget {
  final String subCatId;
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const DuaListScreen({super.key, required this.subCatId, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DuaRepository>();
    final subCat = repo.getSubCategoryData(subCatId);
    final duas = repo.getDuasForSubCategory(subCatId);

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
                    onTap: () => onNavigate('duaCategories'),
                    child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('←', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
                  ),
                  Expanded(child: Text(subCat?.title ?? 'Duas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.text), textAlign: TextAlign.center)),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: duas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(40)),
                          child: const Center(child: Text('🤲', style: TextStyle(fontSize: 36))),
                        ),
                        const SizedBox(height: 20),
                        const Text('No Duas Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.text)),
                        const SizedBox(height: 8),
                        const Text('This category will be populated soon.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: duas.length,
                    itemBuilder: (ctx, i) => _buildDuaCard(duas[i], i),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuaCard(Dua dua, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arabic
            Text(dua.arabic, style: const TextStyle(fontSize: 24, color: AppTheme.text, height: 2), textAlign: TextAlign.right),
            const SizedBox(height: 20),

            // Transliteration
            Text(dua.transliteration, style: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),

            // Translation
            Text(dua.translation, style: const TextStyle(fontSize: 15, color: Color(0xFF334155), height: 1.6, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),

            // Reference
            if (dua.reference.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(dua.reference, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              ),
          ],
        ),
      ),
    );
  }
}
