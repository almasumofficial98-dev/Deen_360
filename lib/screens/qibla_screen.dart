import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme.dart';

class QiblaScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const QiblaScreen({super.key, required this.onNavigate});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  // Kaaba coordinates
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _qiblaDirection; // Qibla bearing from north
  double _compassHeading = 0;
  bool _hasPermission = false;
  bool _loading = true;
  String _statusMessage = 'Calibrating...';
  StreamSubscription<CompassEvent>? _compassSubscription;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initCompass() async {
    // 1. Get location
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _loading = false; _statusMessage = 'Location services disabled'; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _loading = false; _statusMessage = 'Location permission denied'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _loading = false; _statusMessage = 'Location permanently denied.\nOpen Settings to allow.'; });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );

      _qiblaDirection = _calculateQibla(position.latitude, position.longitude);
      _hasPermission = true;

      setState(() { _loading = false; _statusMessage = 'Point your phone towards the Kaaba'; });
    } catch (e) {
      setState(() { _loading = false; _statusMessage = 'Failed to get location: $e'; });
      return;
    }

    // 2. Listen to compass
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() => _compassHeading = event.heading!);
      }
    });
  }

  /// Calculate Qibla direction (bearing from user to Kaaba)
  double _calculateQibla(double lat, double lng) {
    final lat1 = lat * pi / 180;
    final lng1 = lng * pi / 180;
    final lat2 = _kaabaLat * pi / 180;
    final lng2 = _kaabaLng * pi / 180;

    final dLng = lng2 - lng1;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    // The needle angle: qibla relative to phone heading
    final needleAngle = _qiblaDirection != null ? (_qiblaDirection! - _compassHeading) : 0.0;
    final needleRadians = needleAngle * pi / 180;

    // Is the phone roughly pointing to Qibla? (within 5 degrees)
    final isAligned = _qiblaDirection != null && (needleAngle.abs() < 5 || (360 - needleAngle.abs()) < 5);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigate('home'),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Text('←', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    ),
                  ),
                  Expanded(
                    child: Column(children: [
                      const Text('Qibla Compass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.text)),
                      const SizedBox(height: 1),
                      Text('${_qiblaDirection?.toStringAsFixed(1) ?? '--'}° from North', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ]),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: _loading
                ? _buildLoadingState()
                : !_hasPermission
                  ? _buildErrorState()
                  : _buildCompass(needleRadians, isAligned),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primary)),
          const SizedBox(height: 24),
          const Text('Calibrating Compass...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.text)),
          const SizedBox(height: 8),
          const Text('Getting your location', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(50)),
              child: const Center(child: Icon(Icons.location_off_rounded, size: 48, color: AppTheme.error)),
            ),
            const SizedBox(height: 24),
            const Text('Location Required', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.text)),
            const SizedBox(height: 12),
            Text(_statusMessage, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                setState(() => _loading = true);
                _initCompass();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(100)),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(double needleRadians, bool isAligned) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Hero info card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: isAligned ? AppGradients.primary : null,
              color: isAligned ? null : AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: isAligned ? null : Border.all(color: const Color(0xFFF1F5F9)),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  isAligned ? '🕋' : '🧭',
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAligned ? 'Qibla Aligned!' : 'Finding Qibla...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isAligned ? Colors.white : AppTheme.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAligned ? 'You are facing the Kaaba' : _statusMessage,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isAligned ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Compass
        Expanded(
          child: Center(
            child: SizedBox(
              width: 300, height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      return Container(
                        width: 280 + (_pulseController.value * 20),
                        height: 280 + (_pulseController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isAligned ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                            width: 2,
                          ),
                        ),
                      );
                    },
                  ),

                  // Compass base (rotates with device)
                  Transform.rotate(
                    angle: -_compassHeading * pi / 180,
                    child: Container(
                      width: 260, height: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // N S E W labels
                          const Positioned(top: 20, child: Text('N', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.error))),
                          const Positioned(bottom: 20, child: Text('S', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                          const Positioned(right: 20, child: Text('E', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),
                          const Positioned(left: 20, child: Text('W', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)))),

                          // Degree markers
                          ...List.generate(36, (i) {
                            final angle = i * 10 * pi / 180;
                            final isCardinal = i % 9 == 0;
                            return Transform.rotate(
                              angle: angle,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: isCardinal ? 2.5 : 1,
                                  height: isCardinal ? 14 : 8,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: BoxDecoration(
                                    color: isCardinal ? AppTheme.text : const Color(0xFFD1D5DB),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  // Qibla needle (points towards Qibla)
                  Transform.rotate(
                    angle: needleRadians,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Needle tip
                        Container(
                          width: 4,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [isAligned ? AppTheme.primary : AppTheme.error, Colors.transparent],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Center kaaba icon
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: isAligned ? AppTheme.primary : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floating,
                            border: Border.all(color: isAligned ? AppTheme.primaryDark : const Color(0xFFE5E7EB), width: 3),
                          ),
                          child: Center(
                            child: Text(
                              '🕋',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tail
                        Container(
                          width: 3,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom info
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('Bearing', '${_qiblaDirection?.toStringAsFixed(1) ?? "--"}°'),
                Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
                _buildInfoItem('Heading', '${_compassHeading.toStringAsFixed(0)}°'),
                Container(width: 1, height: 30, color: const Color(0xFFF1F5F9)),
                _buildInfoItem('Status', isAligned ? 'Aligned ✓' : 'Seeking...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.text)),
      ],
    );
  }
}
