// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class LanguageController extends ChangeNotifier {
  final translator = GoogleTranslator();
  bool _isEnglish = true;

  bool get isEnglish => _isEnglish;

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  Future<String> translateText(String text) async {
    if (_isEnglish) return text;

    try {
      final translation = await translator.translate(text, to: 'vi');
      return translation.text;
    } catch (e) {
      print('Translation error: $e');
      return text;
    }
  }
}
