import 'movie.dart';

class Session {
  final Movie movie;
  final DateTime startsAt;

  const Session({required this.movie, required this.startsAt});

  int get hall => movie.hall;

  /// Ключ сеанса, по которому хранятся занятые места: m01_20261020_1600.
  String get id {
    String two(int v) => v.toString().padLeft(2, '0');
    final d = startsAt;
    return '${movie.id}_${d.year}${two(d.month)}${two(d.day)}_${two(d.hour)}${two(d.minute)}';
  }

  bool isPast([DateTime? now]) => !startsAt.isAfter(now ?? DateTime.now());

  String get timeText {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(startsAt.hour)}:${two(startsAt.minute)}';
  }

  /// Сеансы фильма на указанный день по его расписанию.
  static List<Session> forDay(Movie movie, DateTime day) {
    return movie.sessions.map((t) {
      final parts = t.split(':');
      return Session(
        movie: movie,
        startsAt: DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1])),
      );
    }).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }
}
