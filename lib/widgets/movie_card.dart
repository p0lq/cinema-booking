import 'package:flutter/material.dart';

import '../models/movie.dart';
import 'poster_image.dart';

class RatingBadge extends StatelessWidget {
  final double rating;
  const RatingBadge(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
      const SizedBox(width: 2),
      Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
    ]);
  }
}

class AgeBadge extends StatelessWidget {
  final String age;
  const AgeBadge(this.age, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(age, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

/// Карточка фильма в общем списке.
class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Hero(tag: 'poster-${movie.id}', child: PosterImage(movie: movie, width: 84, height: 126, radius: 8)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(movie.title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(movie.genre, style: text.bodyMedium),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text(movie.durationText, style: text.bodySmall),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  AgeBadge(movie.ageRating),
                  const SizedBox(width: 12),
                  RatingBadge(movie.rating),
                  const Spacer(),
                  if (!movie.hasSessions)
                    Text('Скоро', style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Узкая карточка для горизонтального блока «Популярное».
class PopularMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  const PopularMovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PosterImage(movie: movie, width: 130, height: 180),
          const SizedBox(height: 6),
          Text(movie.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Row(children: [
            Expanded(child: Text(movie.genre, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall)),
            RatingBadge(movie.rating),
          ]),
        ]),
      ),
    );
  }
}
