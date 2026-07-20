import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_tracker_provider.dart';

class SalahLogSheet extends StatefulWidget {
  final DateTime date;
  final String prayerName;
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  final VoidCallback? onCelebration;

  const SalahLogSheet({
    super.key,
    required this.date,
    required this.prayerName,
    required this.onNavigate,
    this.onCelebration,
  });

  @override
  State<SalahLogSheet> createState() => _SalahLogSheetState();
}

class _SalahLogSheetState extends State<SalahLogSheet> {
  late SalahStatus _status;
  late int _sunnahBefore;
  late int _sunnahAfter;
  late int _nafl;
  late int _witr;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SalahTrackerProvider>();
    final entry = provider.getEntry(widget.date, widget.prayerName);
    _status = entry.status;
    _sunnahBefore = entry.sunnahBefore;
    _sunnahAfter = entry.sunnahAfter;
    _nafl = entry.nafl;
    _witr = entry.witr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final primaryColor = theme.primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.prayerName.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Log Prayer Status',
                    style: TextStyle(
                      color: AppTheme.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // STATUS (Fard Priority)
          _sectionTitle('STATUS (FARD)'),
          const SizedBox(height: 12),
          _buildStatusGrid(primaryColor),
          const SizedBox(height: 24),

          // SUNNAH & OPTIONAL (Evidence-Based)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _sectionTitle('SUNNAH & OPTIONAL')),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  widget.onNavigate('salahGuide');
                },
                child: Text(
                  'Evidence Guide',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildContextualOptions(primaryColor),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                context.read<SalahTrackerProvider>().updateEntry(
                      widget.date,
                      widget.prayerName,
                      SalahEntry(
                        status: _status,
                        sunnahBefore: _sunnahBefore,
                        sunnahAfter: _sunnahAfter,
                        nafl: _nafl,
                        witr: _witr,
                      ),
                    );

                if (_status == SalahStatus.alone ||
                    _status == SalahStatus.jamaat ||
                    _status == SalahStatus.qaza) {
                  widget.onCelebration?.call();
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                shadowColor: primaryColor.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Save Record',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      );

  Widget _buildStatusGrid(Color primary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.3,
      children: [
        _statusTile(
          'In Jamaat',
          SalahStatus.jamaat,
          Icons.groups_rounded,
          const Color(0xFF10B981),
          subtitle: '+27x Reward',
        ),
        _statusTile(
          'Alone',
          SalahStatus.alone,
          Icons.person_rounded,
          primary,
        ),
        _statusTile(
          'Qaza',
          SalahStatus.qaza,
          Icons.history_rounded,
          Colors.amber.shade900,
        ),
        _statusTile(
          'Missed',
          SalahStatus.missed,
          Icons.close_rounded,
          const Color(0xFFF43F5E),
        ),
      ],
    );
  }

  Widget _statusTile(
    String label,
    SalahStatus s,
    IconData icon,
    Color activeColor, {
    String? subtitle,
  }) {
    final active = _status == s;
    return GestureDetector(
      onTap: () => setState(() => _status = active ? SalahStatus.none : s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? activeColor : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
          border: Border.all(
            color: active
                ? Colors.transparent
                : AppTheme.textMuted.withValues(alpha: 0.1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : AppTheme.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: active
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF10B981),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualOptions(Color primary) {
    final name = widget.prayerName;
    return Column(
      children: [
        if (name == 'Fajr')
          _countChoice(
            'Sunnah Before',
            [0, 2],
            _sunnahBefore,
            (v) => setState(() => _sunnahBefore = v),
            primary,
          ),
        if (name == 'Dhuhr') ...[
          _countChoice(
            'Sunnah Before',
            [0, 2, 4],
            _sunnahBefore,
            (v) => setState(() => _sunnahBefore = v),
            primary,
          ),
          _countChoice(
            'Sunnah After',
            [0, 2],
            _sunnahAfter,
            (v) => setState(() => _sunnahAfter = v),
            primary,
          ),
        ],
        if (name == 'Asr')
          _countChoice(
            'Sunnah (Optional)',
            [0, 2, 4],
            _sunnahBefore,
            (v) => setState(() => _sunnahBefore = v),
            primary,
          ),
        if (name == 'Maghrib')
          _countChoice(
            'Sunnah After',
            [0, 2],
            _sunnahAfter,
            (v) => setState(() => _sunnahAfter = v),
            primary,
          ),
        if (name == 'Isha') ...[
          _countChoice(
            'Sunnah After',
            [0, 2],
            _sunnahAfter,
            (v) => setState(() => _sunnahAfter = v),
            primary,
          ),
          _countChoice(
            'Witr',
            [0, 1, 3],
            _witr,
            (v) => setState(() => _witr = v),
            primary,
            isWitr: true,
          ),
        ],
        _naflCounter(primary),
      ],
    );
  }

  Widget _countChoice(
    String label,
    List<int> options,
    int current,
    Function(int) onSelected,
    Color primary, {
    bool isWitr = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final active = current == opt;
              final accentColor = isWitr ? Colors.indigo : primary;
              return GestureDetector(
                onTap: () => onSelected(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active ? accentColor : AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opt == 0 ? 'Off' : '$opt Rakat',
                    style: TextStyle(
                      color: active ? Colors.white : AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _naflCounter(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Nafl (Extra Rakat)',
              style: TextStyle(
                color: AppTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.inputBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_nafl > 0) setState(() => _nafl -= 2);
                  },
                  icon: const Icon(Icons.remove, size: 16),
                ),
                Text(
                  '$_nafl',
                  style: const TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _nafl += 2),
                  icon: const Icon(Icons.add, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
