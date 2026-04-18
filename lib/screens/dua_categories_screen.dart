import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/dua_repository.dart';

class DuaCategoriesScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const DuaCategoriesScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DuaRepository>();
    final categories = repo.categories;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: categories.fold<int>(0, (sum, cat) => sum + cat.subCategories.length + 1) + 1,
          itemBuilder: (ctx, index) {
            if (index == 0) return _buildHeader(context);
            
            int cursor = 1;
            for (final cat in categories) {
              if (index == cursor) {
                cursor++;
                return _buildSectionHeader(cat.icon, cat.title);
              }
              cursor++;
              for (final sub in cat.subCategories) {
                if (index == cursor) {
                  return _buildSubCatCard(sub);
                }
                cursor++;
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onNavigate('home'),
                child: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('←', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))),
              ),
              Expanded(child: Column(children: const [
                Text('Hisnul Muslim', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.text)),
                SizedBox(height: 1),
                Text('Fortress of the Muslim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              ])),
              const SizedBox(width: 44),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Container(
            decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(32), boxShadow: AppShadows.floating),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('DUA LIBRARY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const SizedBox(height: 16),
                const Text('Categorized Supplications', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.3)),
                const SizedBox(height: 12),
                Text('100% Offline Essential Duas', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSubCatCard(SubCategory sub) {
    final hasDuas = sub.duas.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: () => onNavigate('duaList', {'subCatId': sub.id}),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text(sub.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text)),
                    const SizedBox(height: 4),
                    Text(hasDuas ? '${sub.duas.length} Duas' : 'Empty (Add later)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const Text('→', style: TextStyle(fontSize: 20, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
