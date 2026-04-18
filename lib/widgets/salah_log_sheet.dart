import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/salah_tracker_provider.dart';

class SalahLogSheet extends StatefulWidget {
  final DateTime date;
  final String prayerName;

  const SalahLogSheet({
    super.key,
    required this.date,
    required this.prayerName,
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
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(widget.prayerName.toUpperCase(), style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Log your prayer', style: TextStyle(color: AppTheme.text, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 28),
          
          // STATUS (Fard Priority)
          _sectionTitle('STATUS (FARD)'),
          const SizedBox(height: 12),
          _buildStatusGrid(primaryColor),
          const SizedBox(height: 28),

          // SUNNAH & OPTIONAL (Evidence-Based)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('SUNNAH & OPTIONAL'),
              GestureDetector(
                onTap: () {
                  // Navigate to guide inside bottom sheet might be tricky, let's just pop and navigate or show guide button
                },
                child: Text('View evidence-based guide', style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContextualOptions(primaryColor),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
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
                    witr: _witr
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('Save Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(color: AppTheme.textLight, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));

  Widget _buildStatusGrid(Color primary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _statusButton('Alone', SalahStatus.alone, Icons.person_rounded, primary),
        _statusButton('Jamaat', SalahStatus.jamaat, Icons.groups_rounded, primary),
        _statusButton('Qaza', SalahStatus.qaza, Icons.history_rounded, primary),
        _statusButton('Missed', SalahStatus.missed, Icons.close_rounded, primary),
      ],
    );
  }

  Widget _statusButton(String label, SalahStatus s, IconData icon, Color primary) {
    final active = _status == s;
    return GestureDetector(
      onTap: () => setState(() => _status = active ? SalahStatus.none : s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? primary : AppTheme.inputBg,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : AppTheme.textMuted),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: active ? Colors.white : AppTheme.text, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualOptions(Color primary) {
    final name = widget.prayerName;
    return Column(
      children: [
        if (name == 'Fajr') _countChoice('Sunnah Before', [0, 2], _sunnahBefore, (v) => setState(() => _sunnahBefore = v), primary),
        if (name == 'Dhuhr') ...[
          _countChoice('Sunnah Before', [0, 2, 4], _sunnahBefore, (v) => setState(() => _sunnahBefore = v), primary),
          _countChoice('Sunnah After', [0, 2], _sunnahAfter, (v) => setState(() => _sunnahAfter = v), primary),
        ],
        if (name == 'Asr') _countChoice('Sunnah (Optional)', [0, 2, 4], _sunnahBefore, (v) => setState(() => _sunnahBefore = v), primary),
        if (name == 'Maghrib') _countChoice('Sunnah After', [0, 2], _sunnahAfter, (v) => setState(() => _sunnahAfter = v), primary),
        if (name == 'Isha') ...[
          _countChoice('Sunnah After', [0, 2], _sunnahAfter, (v) => setState(() => _sunnahAfter = v), primary),
          _countChoice('Witr', [0, 1, 3], _witr, (v) => setState(() => _witr = v), primary, isWitr: true),
        ],
        _naflCounter(primary),
      ],
    );
  }

  Widget _countChoice(String label, List<int> options, int current, Function(int) onSelected, Color primary, {bool isWitr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w800))),
          Wrap(
            spacing: 8,
            children: options.map((opt) {
              final active = current == opt;
              return GestureDetector(
                onTap: () => onSelected(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? (isWitr ? Colors.indigo : primary) : AppTheme.inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    opt == 0 ? 'Off' : '$opt R',
                    style: TextStyle(color: active ? Colors.white : AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w900),
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
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Expanded(child: Text('Nafl (Open-ended)', style: TextStyle(color: AppTheme.text, fontSize: 15, fontWeight: FontWeight.w800))),
          Container(
            decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                IconButton(onPressed: () { if (_nafl > 0) setState(() => _nafl -= 2); }, icon: const Icon(Icons.remove, size: 16)),
                Text('$_nafl', style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => setState(() => _nafl += 2), icon: const Icon(Icons.add, size: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
