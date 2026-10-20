import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/booking_provider.dart';
import '../widgets/movie_card.dart';
import '../widgets/poster_image.dart';
import 'sessions_screen.dart';

class MovieDetailsScreen extends StatelessWidget {
  final String movieId;
  const MovieDetailsScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context) {
    final movie = context.watch<BookingProvider>().movieById(movieId);
    if (movie == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Фильм не найден')));
    }
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Hero(tag: 'poster-${movie.id}', child: PosterImage(movie: movie, width: 140, height: 210)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(movie.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _InfoRow(icon: Icons.category_outlined, text: movie.genre),
              _InfoRow(icon: Icons.schedule, text: '${movie.duration} мин (${movie.durationText})'),
              _InfoRow(icon: Icons.meeting_room_outlined, text: 'Зал ${movie.hall}'),
              const SizedBox(height: 8),
              Row(children: [AgeBadge(movie.ageRating), const SizedBox(width: 12), RatingBadge(movie.rating)]),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        Text('О фильме', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(movie.description, style: text.bodyLarge),
        const SizedBox(height: 20),
        Text('Сеансы', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (movie.hasSessions) ...[
          Text('Ежедневно, ближайшие 7 дней:', style: text.bodyMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in movie.sessions) Chip(label: Text(t), avatar: const Icon(Icons.access_time, size: 18)),
          ]),
        ] else
          Card(
            color: scheme.tertiaryContainer,
            child: const ListTile(
              leading: Icon(Icons.event_busy),
              title: Text('Доступных сеансов нет'),
              subtitle: Text('Расписание появится ближе к премьере.'),
            ),
          ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.event_seat),
            label: const Text('Выбрать сеанс'),
            onPressed: movie.hasSessions
                ? () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => SessionsScreen(movieId: movie.id)))
                : null,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 6), Expanded(child: Text(text))]),
      );
}
