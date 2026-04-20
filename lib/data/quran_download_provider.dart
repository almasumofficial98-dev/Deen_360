import 'package:flutter/material.dart';
import 'quran_repository.dart';

class QuranDownloadProvider extends ChangeNotifier {
  final QuranRepository _repository;
  
  bool _isDownloading = false;
  bool _isDownloadingJuz = false;
  double _progress = 0.0;
  double _juzProgress = 0.0;
  int _downloadedCount = 0;
  int _downloadedJuzCount = 0;
  Set<int> _offlineSurahs = {};
  Set<int> _offlineJuz = {};
  String _currentStatus = '';
  bool _stopSignal = false;

  QuranDownloadProvider(this._repository) {
    _init();
  }

  bool get isDownloading => _isDownloading || _isDownloadingJuz;
  bool get isDownloadingSurah => _isDownloading;
  bool get isDownloadingJuz => _isDownloadingJuz;
  double get progress => _isDownloadingJuz ? _juzProgress : _progress;
  int get downloadedCount => _downloadedCount;
  int get downloadedJuzCount => _downloadedJuzCount;
  String get currentStatus => _currentStatus;
  Set<int> get offlineSurahs => _offlineSurahs;
  Set<int> get offlineJuz => _offlineJuz;

  Future<void> _init() async {
    await refreshOfflineStatus();
  }

  Future<void> refreshOfflineStatus() async {
    // 1. Surahs
    Set<int> downloadedSurahs = {};
    for (int i = 1; i <= 114; i++) {
      if (await _repository.isSurahDownloaded(i)) {
        downloadedSurahs.add(i);
      }
    }
    _offlineSurahs = downloadedSurahs;
    _downloadedCount = downloadedSurahs.length;

    // 2. Juz
    Set<int> downloadedJuz = {};
    for (int i = 1; i <= 30; i++) {
      if (await _repository.isJuzDownloaded(i)) {
        downloadedJuz.add(i);
      }
    }
    _offlineJuz = downloadedJuz;
    _downloadedJuzCount = downloadedJuz.length;
    notifyListeners();
  }

  void cancelDownload() {
    _stopSignal = true;
    _currentStatus = 'Pausing...';
    notifyListeners();
  }

  Future<void> downloadAll() async {
    if (_isDownloading || _isDownloadingJuz) return;
    
    _stopSignal = false;
    _isDownloading = true;
    _progress = 0;
    _currentStatus = 'Connecting...';
    notifyListeners();

    try {
      for (int i = 1; i <= 114; i++) {
        if (_stopSignal) {
          _currentStatus = 'Paused at Surah ${i-1}';
          break;
        }
        if (_offlineSurahs.contains(i)) {
          _progress = i / 114;
          continue;
        }

        _currentStatus = 'Downloading Surah $i...';
        notifyListeners();

        for (final lang in ['en', 'hi', 'bn', 'ur']) {
          await _repository.fetchAndSaveSurah(i, language: lang);
        }
        
        _offlineSurahs.add(i);
        _downloadedCount = _offlineSurahs.length;
        _progress = i / 114;
        notifyListeners();
        
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _currentStatus = 'Download Complete';
    } catch (e) {
      _currentStatus = 'Download Interrupted: $e';
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> downloadAllJuz() async {
    if (_isDownloading || _isDownloadingJuz) return;

    _stopSignal = false;
    _isDownloadingJuz = true;
    _juzProgress = 0;
    _currentStatus = 'Connecting...';
    notifyListeners();

    try {
      for (int i = 1; i <= 30; i++) {
        if (_stopSignal) {
          _currentStatus = 'Paused at Para ${i-1}';
          break;
        }
        if (_offlineJuz.contains(i)) {
          _juzProgress = i / 30;
          continue;
        }

        _currentStatus = 'Downloading Para $i...';
        notifyListeners();

        for (final lang in ['en', 'hi', 'bn', 'ur']) {
          await _repository.fetchAndSaveJuz(i, language: lang);
        }
        
        _offlineJuz.add(i);
        _downloadedJuzCount = _offlineJuz.length;
        _juzProgress = i / 30;
        notifyListeners();
        
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _currentStatus = 'Download Complete';
    } catch (e) {
      _currentStatus = 'Download Interrupted: $e';
    } finally {
      _isDownloadingJuz = false;
      notifyListeners();
    }
  }

  Future<void> clearDownloads() async {
    await _repository.clearQuranCache();
    _offlineSurahs.clear();
    _offlineJuz.clear();
    _downloadedCount = 0;
    _downloadedJuzCount = 0;
    _progress = 0;
    _juzProgress = 0;
    notifyListeners();
  }
}
