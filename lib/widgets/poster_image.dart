import 'package:flutter/material.dart';

import '../models/movie.dart';

class PosterImage extends StatelessWidget {
  final Movie movie;
  final double? width;
  final double? height;
  final double radius;

  const PosterImage({super.key, required this.movie, this.width, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.movie_outlined, color: scheme.onSurfaceVariant, size: 40),
    );

    final image = movie.poster.startsWith('http')
        ? Image.network(movie.poster, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder)
        : Image.asset(movie.poster, width: width, height: height, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => placeholder);

    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: image);
  }
}
