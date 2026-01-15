import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Kaydetmek için

class ReadingProvider with ChangeNotifier {
  // --- ZAMANLAYICI DEĞİŞKENLERİ ---
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isRunning = false;
  String? _currentBookId;

  // --- HEDEF DEĞİŞKENLERİ (YENİ) ---
  int _bookGoal = 5;    // Varsayılan Aylık Kitap Hedefi
  int _pageGoal = 1000; // Varsayılan Aylık Sayfa Hedefi

  // --- GETTER'LAR ---
  int get secondsElapsed => _secondsElapsed;
  bool get isRunning => _isRunning;
  String? get currentBookId => _currentBookId;
  
  int get bookGoal => _bookGoal; // YENİ
  int get pageGoal => _pageGoal; // YENİ

  String get timerString {
    final minutes = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final seconds = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // Kurucu Metot: Uygulama açılınca hedefleri hafızadan yükle
  ReadingProvider() {
    _loadGoals();
  }

  // --- HEDEF FONKSİYONLARI (YENİ) ---
  
  // 1. Hedefleri Yükle
  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    _bookGoal = prefs.getInt('bookGoal') ?? 5;
    _pageGoal = prefs.getInt('pageGoal') ?? 1000;
    notifyListeners();
  }

  // 2. Hedefleri Güncelle ve Kaydet
  Future<void> updateGoals(int newBookGoal, int newPageGoal) async {
    _bookGoal = newBookGoal;
    _pageGoal = newPageGoal;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookGoal', newBookGoal);
    await prefs.setInt('pageGoal', newPageGoal);
  }

  // --- ZAMANLAYICI FONKSİYONLARI ---

  void startReading(String? bookId) {
    _currentBookId = bookId;
    if (!_isRunning) {
      _startTimer();
    }
    notifyListeners();
  }

  void toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void resetTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _isRunning = false;
    _currentBookId = null;
    notifyListeners();
  }
}