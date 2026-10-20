import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import '../widgets/status_chip.dart';
import 'e_ticket_screen.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().bookings;

    return Scaffold(
      appBar: AppBar(title: const Text('История бронирований')),
      body: bookings.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.confirmation_number_outlined, size: 56),
                  SizedBox(height: 12),
                  Text('Бронирований пока нет', textAlign: TextAlign.center),
                ]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookings.length,
              itemBuilder: (context, i) {
                final b = bookings[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    title: Text(b.movieTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 4),
                      Text('№ ${b.id}'),
                      Text('${formatDateTime(b.sessionStart)} · билетов: ${b.seats.length}'),
                      Text(formatPrice(b.total), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    trailing: StatusChip(b.effectiveStatus()),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => ETicketScreen(bookingId: b.id))),
                  ),
                );
              },
            ),
    );
  }
}
