import 'package:flutter/material.dart';
import 'quran_repository.dart';

class QuranDownloadProvider extends ChangeNotifier {
  final QuranRepository _repository;
  
  bool _isDownloading = false;
  double _progress = 0.0;
  int _downloadedCount = 0;
  Set<int> _offlineSurahs = {};
  String _currentStatus = '';

  QuranDownloadProvider(this._repository) {
    _init();
  }

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  int get downloadedCount => _downloadedCount;
  String get currentStatus => _currentStatus;
  Set<int> get offlineSurahs => _offlineSurahs;

  Future<void> _init() async {
    await refreshOfflineStatus();
  }

  Future<void> refreshOfflineStatus() async {
    Set<int> downloaded = {};
    for (int i = 1; i <= 114; i++) {
      if (await _repository.isSurahDownloaded(i)) {
        downloaded.add(i);
      }
    }
    _offlineSurahs = downloaded;
    _downloadedCount = downloaded.length;
    notifyListeners();
  }

  Future<void> downloadAll() async {
    if (_isDownloading) return;
    
    _isDownloading = true;
    _progress = 0;
    _currentStatus = 'Connecting...';
    notifyListeners();

    try {
      for (int i = 1; i <= 114; i++) {
        if (_offlineSurahs.contains(i)) {
          _progress = i / 114;
          continue;
        }

        _currentStatus = 'Downloading Surah $i...';
        notifyListeners();

        // Download and save
        await _repository.fetchAndSaveSurah(i);
        
        _offlineSurahs.add(i);
        _downloadedCount = _offlineSurahs.length;
        _progress = i / 114;
        notifyListeners();
        
        // Small delay to prevent rate limiting and keep UI responsive
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

  Future<void> clearDownloads() async {
    await _repository.clearQuranCache();
    _offlineSurahs.clear();
    _downloadedCount = 0;
    _progress = 0;
    notifyListeners();
  }
}
