import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/session.dart';
import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import 'seat_selection_screen.dart';

class SessionsScreen extends StatefulWidget {
  final String movieId;

  /// Сколько дней вперёд открыта продажа.
  static const daysAhead = 7;

  const SessionsScreen({super.key, required this.movieId});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late final List<DateTime> _days;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _days = List.generate(SessionsScreen.daysAhead, (i) => today.add(Duration(days: i)));
    _selectedDay = _days.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final movie = provider.movieById(widget.movieId);
    if (movie == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Фильм не найден')));
    }
    final sessions = Session.forDay(movie, _selectedDay);
    final now = DateTime.now();
    final hasFuture = sessions.any((s) => !s.isPast(now));

    return Scaffold(
      appBar: AppBar(title: Text('Сеансы: ${movie.title}')),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Дата', style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _days[i];
              final label = i == 0 ? 'Сегодня' : (i == 1 ? 'Завтра' : formatDay(d));
              return ChoiceChip(
                label: Text(label),
                selected: isSameDay(d, _selectedDay),
                onSelected: (_) => setState(() => _selectedDay = d),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Время · ${formatDay(_selectedDay)} · зал ${movie.hall}',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        if (!hasFuture)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('На эту дату сеансов больше нет. Выберите другой день.'),
          ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            for (final s in sessions) _SessionTile(session: s, isPast: s.isPast(now)),
          ]),
        ),
      ]),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final bool isPast;
  const _SessionTile({required this.session, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final free = isPast ? null : context.read<BookingProvider>().freeSeatsCount(session);
    return Card(
      child: ListTile(
        enabled: !isPast && free! > 0,
        leading: Icon(isPast ? Icons.history : Icons.access_time),
        title: Text(session.timeText,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                decoration: isPast ? TextDecoration.lineThrough : null)),
        subtitle: Text(isPast
            ? 'Сеанс уже прошёл'
            : (free == 0 ? 'Мест нет' : 'Свободно мест: $free')),
        trailing: isPast ? null : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => SeatSelectionScreen(session: session))),
      ),
    );
  }
}
