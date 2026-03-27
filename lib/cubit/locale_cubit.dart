import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit to manage the app's locale/language state
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(const Locale('en'));

  /// Change the app's language
  void changeLanguage(Locale locale) {
    emit(locale);
  }

  /// Switch to English
  void setEnglish() {
    emit(const Locale('en'));
  }

  /// Switch to Azerbaijani
  void setAzerbaijani() {
    emit(const Locale('az'));
  }

  /// Toggle between English and Azerbaijani
  void toggleLanguage() {
    if (state.languageCode == 'en') {
      emit(const Locale('az'));
    } else {
      emit(const Locale('en'));
    }
  }
}
