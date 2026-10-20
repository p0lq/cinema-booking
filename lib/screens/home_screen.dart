import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../state/booking_provider.dart';
import '../state/theme_provider.dart';
import '../widgets/movie_card.dart';
import 'booking_history_screen.dart';
import 'movie_details_screen.dart';

const cinemaName = 'Кинотеатр «Звезда»';

class MovieFilter {
  final double minRating;
  final int maxDuration;
  const MovieFilter({this.minRating = 0, this.maxDuration = maxPossibleDuration});

  static const maxPossibleDuration = 180;

  bool get isActive => minRating > 0 || maxDuration < maxPossibleDuration;

  bool matches(Movie m) => m.rating >= minRating && m.duration <= maxDuration;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _genre;
  MovieFilter _filter = const MovieFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openMovie(Movie movie) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: movie.id)));
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<MovieFilter>(
      context: context,
      showDragHandle: true,
      builder: (_) => _FilterSheet(initial: _filter),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cinemaName),
          Text('Cinema Booking', style: TextStyle(fontSize: 12)),
        ]),
        actions: [
          IconButton(
            tooltip: theme.isDark ? 'Светлая тема' : 'Тёмная тема',
            icon: Icon(theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: theme.toggle,
          ),
          IconButton(
            tooltip: 'История бронирований',
            icon: const Icon(Icons.confirmation_number_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const BookingHistoryScreen())),
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(BookingProvider provider) {
    if (provider.loading) return const Center(child: CircularProgressIndicator());
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(provider.error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: provider.load, child: const Text('Повторить')),
          ]),
        ),
      );
    }

    final q = _query.trim().toLowerCase();
    final filtered = provider.movies
        .where((m) => q.isEmpty || m.title.toLowerCase().contains(q))
        .where((m) => _genre == null || m.genre == _genre)
        .where(_filter.matches)
        .toList();
    final popular = provider.movies.where((m) => m.rating >= 8.0 && m.hasSessions).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final showPopular = q.isEmpty && _genre == null && !_filter.isActive;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по названию',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Фильтры',
              onPressed: _openFilterSheet,
              icon: Badge(isLabelVisible: _filter.isActive, child: const Icon(Icons.tune)),
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _genreChip('Все', null),
              for (final g in provider.genres) _genreChip(g, g),
            ],
          ),
        ),
      ),
      if (showPopular && popular.isNotEmpty) ...[
        _sectionTitle('Популярное'),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => PopularMovieCard(movie: popular[i], onTap: () => _openMovie(popular[i])),
            ),
          ),
        ),
      ],
      _sectionTitle(showPopular ? 'Все фильмы' : 'Найдено: ${filtered.length}'),
      if (filtered.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Фильмы не найдены. Измените запрос или фильтры.', textAlign: TextAlign.center),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          sliver: SliverList.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) => MovieCard(movie: filtered[i], onTap: () => _openMovie(filtered[i])),
          ),
        ),
    ]);
  }

  Widget _genreChip(String label, String? value) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _genre == value,
          onSelected: (_) => setState(() => _genre = value),
        ),
      );

  Widget _sectionTitle(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
      );
}

class _FilterSheet extends StatefulWidget {
  final MovieFilter initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double _minRating = widget.initial.minRating;
  late double _maxDuration = widget.initial.maxDuration.toDouble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Фильтры', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('Рейтинг не ниже: ${_minRating.toStringAsFixed(1)}'),
        Slider(
          value: _minRating,
          max: 9,
          divisions: 18,
          label: _minRating.toStringAsFixed(1),
          onChanged: (v) => setState(() => _minRating = v),
        ),
        Text(_maxDuration >= MovieFilter.maxPossibleDuration
            ? 'Продолжительность: любая'
            : 'Продолжительность до ${_maxDuration.round()} мин'),
        Slider(
          value: _maxDuration,
          min: 80,
          max: MovieFilter.maxPossibleDuration.toDouble(),
          divisions: 10,
          label: '${_maxDuration.round()} мин',
          onChanged: (v) => setState(() => _maxDuration = v),
        ),
        const SizedBox(height: 8),
        Row(children: [
          TextButton(
            onPressed: () => Navigator.pop(context, const MovieFilter()),
            child: const Text('Сбросить'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, MovieFilter(minRating: _minRating, maxDuration: _maxDuration.round())),
            child: const Text('Применить'),
          ),
        ]),
      ]),
    );
  }
}
