import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking.dart';
import '../models/movie.dart';

/// Локальное хранилище на shared_preferences. Все данные лежат в JSON.
class StorageService {
  static const _moviesKey = 'movies';
  static const _occupiedKey = 'occupied_seats';
  static const _bookingsKey = 'bookings';
  static const _darkThemeKey = 'dark_theme';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  static Future<StorageService> create() async => StorageService(await SharedPreferences.getInstance());

  List<Movie>? loadMovies() {
    final raw = _prefs.getString(_moviesKey);
    if (raw == null) return null;
    return (jsonDecode(raw) as List).map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMovies(List<Movie> movies) =>
      _prefs.setString(_moviesKey, jsonEncode(movies.map((m) => m.toJson()).toList()));

  /// sessionId -> занятые места этого сеанса.
  Map<String, Set<String>> loadOccupied() {
    final raw = _prefs.getString(_occupiedKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, Set<String>.from(v as List)));
  }

  Future<void> saveOccupied(Map<String, Set<String>> occupied) =>
      _prefs.setString(_occupiedKey, jsonEncode(occupied.map((k, v) => MapEntry(k, v.toList()))));

  List<Booking> loadBookings() {
    final raw = _prefs.getString(_bookingsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveBookings(List<Booking> bookings) =>
      _prefs.setString(_bookingsKey, jsonEncode(bookings.map((b) => b.toJson()).toList()));

  bool loadDarkTheme() => _prefs.getBool(_darkThemeKey) ?? false;

  Future<void> saveDarkTheme(bool value) => _prefs.setBool(_darkThemeKey, value);
}
