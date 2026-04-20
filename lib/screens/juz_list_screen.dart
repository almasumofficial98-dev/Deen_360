import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../data/quran_download_provider.dart';

class JuzListScreen extends StatelessWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  const JuzListScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final downloader = context.watch<QuranDownloadProvider>();
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onNavigate('pop'),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(14)),
                      child: const Center(child: Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.text)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Read by Para', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.text, letterSpacing: -0.5)),
                        Text('30 Divisions of the Noble Quran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: 31, // +1 for the download card
                itemBuilder: (context, index) {
                  if (index == 0) return _buildDownloadManager(context);
                  final juzNum = index;
                  return _buildJuzItem(context, juzNum);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadManager(BuildContext context) {
    final downloader = context.watch<QuranDownloadProvider>();
    final theme = context.watch<ThemeProvider>();
    
    if (downloader.downloadedJuzCount == 30 && !downloader.isDownloadingJuz) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.download_for_offline_rounded, color: theme.primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        downloader.isDownloadingJuz ? 'Downloading Paras...' : 'Tilawat Offline',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        downloader.isDownloadingJuz ? downloader.currentStatus : '${downloader.downloadedJuzCount}/30 Paras offline',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                if (downloader.isDownloadingJuz)
                  GestureDetector(
                    onTap: () => downloader.cancelDownload(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('Pause', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  )
                else if (downloader.downloadedJuzCount < 30)
                  GestureDetector(
                    onTap: () => downloader.downloadAllJuz(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Download All', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  ),
                if (downloader.isDownloadingJuz) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, value: downloader.progress, color: theme.primaryColor),
                  ),
                ],
              ],
            ),
            if (downloader.isDownloadingJuz) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: downloader.progress,
                  minHeight: 6,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  color: theme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJuzItem(BuildContext context, int number) {
    final theme = context.watch<ThemeProvider>();
    final downloader = context.watch<QuranDownloadProvider>();
    final isOffline = downloader.offlineJuz.contains(number);
    final primaryColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onNavigate('juzContent', {'number': number}),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('$number', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Para $number', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.text)),
                          if (isOffline) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                          ],
                        ],
                      ),
                      Text(isOffline ? 'Juz $number • OFFLINE' : 'Juz $number of the Quran', 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
