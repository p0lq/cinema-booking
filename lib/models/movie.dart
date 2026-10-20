class Movie {
  final String id;
  final String title;
  final String description;
  final String genre;

  /// Продолжительность в минутах.
  final int duration;
  final String ageRating;
  final String poster;
  final double rating;
  final int hall;

  /// Время сеансов в формате HH:mm. Расписание одинаковое на каждый день.
  final List<String> sessions;

  const Movie({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.duration,
    required this.ageRating,
    required this.poster,
    required this.rating,
    required this.hall,
    required this.sessions,
  });

  bool get hasSessions => sessions.isNotEmpty;

  String get durationText {
    final h = duration ~/ 60;
    final m = duration % 60;
    return h > 0 ? '$h ч $m мин' : '$m мин';
  }

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        genre: json['genre'] as String,
        duration: json['duration'] as int,
        ageRating: json['ageRating'] as String,
        poster: json['poster'] as String,
        rating: (json['rating'] as num).toDouble(),
        hall: json['hall'] as int,
        sessions: List<String>.from(json['sessions'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'genre': genre,
        'duration': duration,
        'ageRating': ageRating,
        'poster': poster,
        'rating': rating,
        'hall': hall,
        'sessions': sessions,
      };
}
