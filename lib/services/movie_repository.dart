import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/movie.dart';
import 'storage_service.dart';

class MovieRepository {
  final StorageService storage;
  final AssetBundle bundle;

  MovieRepository(this.storage, {AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  /// При первом запуске каталог читается из assets/data/movies.json
  /// и сохраняется локально, дальше берётся из хранилища.
  Future<List<Movie>> loadMovies() async {
    final cached = storage.loadMovies();
    if (cached != null && cached.isNotEmpty) return cached;

    final raw = await bundle.loadString('assets/data/movies.json');
    final movies = (jsonDecode(raw) as List).map((e) => Movie.fromJson(e as Map<String, dynamic>)).toList();
    await storage.saveMovies(movies);
    return movies;
  }
}
