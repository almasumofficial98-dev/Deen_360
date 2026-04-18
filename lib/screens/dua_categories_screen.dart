import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
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
                  return _buildSubCatCard(context, sub);
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
                  child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text))),
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
            decoration: BoxDecoration(gradient: context.watch<ThemeProvider>().activeGradient, borderRadius: BorderRadius.circular(32), boxShadow: AppShadows.dynamicFloating(context.watch<ThemeProvider>().primaryColor)),
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

  Widget _buildSectionHeader(String iconKey, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
      child: Row(
        children: [
          Icon(_mapIcon(iconKey), size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSubCatCard(BuildContext context, SubCategory sub) {
    final hasDuas = sub.duas.isNotEmpty;
    final primaryColor = context.watch<ThemeProvider>().primaryColor;
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
            boxShadow: AppShadows.dynamicSoft(primaryColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
                child: Center(child: Icon(_mapIcon(sub.icon), size: 22, color: primaryColor)),
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
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _mapIcon(String key) {
    switch (key.toLowerCase()) {
      // Descriptive Keys
      case 'core': return Icons.explore_rounded;
      case 'explore': return Icons.explore_rounded;
      case 'morning': return Icons.wb_twilight_rounded;
      case 'evening': return Icons.brightness_3_rounded;
      case 'sleep': return Icons.bedtime_rounded;
      case 'bedtime': return Icons.bedtime_rounded;
      case 'awake': return Icons.alarm_rounded;
      case 'mosque': return Icons.mosque_rounded;
      case 'water': return Icons.opacity_rounded;
      case 'clean': return Icons.auto_awesome_rounded;
      case 'walk': return Icons.directions_walk_rounded;
      case 'door': return Icons.sensor_door_rounded;
      case 'dua': return Icons.pan_tool_alt_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'mood': return Icons.mood_rounded;
      case 'drink': return Icons.local_drink_rounded;
      case 'clothes': return Icons.checkroom_rounded;
      case 'home': return Icons.home_rounded;
      case 'person': return Icons.person_rounded;
      case 'sad': return Icons.sentiment_dissatisfied_rounded;
      case 'travel': return Icons.card_travel_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'health': return Icons.health_and_safety_rounded;
      case 'security': return Icons.security_rounded;
      case 'book': return Icons.menu_book_rounded;
      case 'knowledge': return Icons.psychology_rounded;
      case 'favorite': return Icons.favorite_rounded;
      case 'group': return Icons.group_rounded;
      case 'payments': return Icons.payments_rounded;
      case 'nature': return Icons.terrain_rounded;
      case 'flash': return Icons.bolt_rounded;
      case 'night': return Icons.nights_stay_rounded;
      case 'work': return Icons.work_rounded;
      case 'wc': return Icons.wc_rounded;

      // Legacy Emoji Fallbacks
      case "🧭": return Icons.explore_rounded;
      case "🌅": return Icons.wb_twilight_rounded;
      case "🌆": return Icons.wb_sunny_rounded;
      case "🌙": return Icons.nights_stay_rounded;
      case "🛏️": case "🛏": return Icons.bedtime_rounded;
      case "🥱": return Icons.alarm_rounded;
      case "🕌": return Icons.mosque_rounded;
      case "💧": return Icons.opacity_rounded;
      case "✨": return Icons.auto_awesome_rounded;
      case "🚶": return Icons.directions_walk_rounded;
      case "🚪": return Icons.sensor_door_rounded;
      case "🤲": return Icons.pan_tool_alt_rounded;
      case "🍽️": case "🍽": case "🍴": return Icons.restaurant_rounded;
      case "😋": return Icons.mood_rounded;
      case "🥛": return Icons.local_drink_rounded;
      case "👕": return Icons.checkroom_rounded;
      case "🏠": return Icons.home_rounded;
      case "🚻": return Icons.wc_rounded;
      case "🧼": return Icons.cleaning_services_rounded;
      case "😔": return Icons.sentiment_dissatisfied_rounded;
      case "😢": return Icons.sentiment_very_dissatisfied_rounded;
      case "😠": return Icons.sentiment_very_dissatisfied_rounded;
      case "🧳": return Icons.card_travel_rounded;
      case "🚗": return Icons.directions_car_rounded;
      case "✈️": case "✈": return Icons.flight_takeoff_rounded;
      case "🏥": return Icons.medical_services_rounded;
      case "🤒": return Icons.sick_rounded;
      case "💐": return Icons.local_florist_rounded;
      case "🛡️": case "🛡": return Icons.security_rounded;
      case "🧿": return Icons.remove_red_eye_rounded;
      case "👿": return Icons.warning_amber_rounded;
      case "📿": return Icons.auto_fix_high_rounded;
      case "🕋": return Icons.auto_awesome_mosaic_rounded;
      case "🧠": return Icons.psychology_rounded;
      case "📚": return Icons.menu_book_rounded;
      case "🎓": return Icons.school_rounded;
      case "❤️": return Icons.favorite_rounded;
      case "👨‍👩‍👧‍👦": return Icons.group_rounded;
      case "💍": return Icons.favorite_border_rounded;
      case "⚔️": case "⚔": return Icons.gavel_rounded;
      case "💳": return Icons.credit_card_rounded;
      case "⛰️": case "⛰": return Icons.terrain_rounded;
      case "⛓️": case "⛓": return Icons.link_off_rounded;
      case "🌧️": case "🌧": return Icons.cloudy_snowing;
      case "⚡": return Icons.flash_on_rounded;
      case "💨": return Icons.air_rounded;
      case "💼": return Icons.business_center_rounded;
      case "💰": return Icons.payments_rounded;
      case "🏢": return Icons.apartment_rounded;
      case "🤝": return Icons.handshake_rounded;
      case "🤧": return Icons.healing_rounded;
      case "👥": return Icons.people_rounded;
      default: return Icons.category_rounded;
    }
  }
}
