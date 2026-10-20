import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/booking.dart';
import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import '../widgets/status_chip.dart';
import 'booking_details_screen.dart';
import 'home_screen.dart';

class ETicketScreen extends StatelessWidget {
  final String bookingId;

  /// true, если экран открыт сразу после оформления.
  final bool justCreated;

  const ETicketScreen({super.key, required this.bookingId, this.justCreated = false});

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>().bookingById(bookingId);
    if (booking == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Бронирование не найдено')));
    }
    final status = booking.effectiveStatus();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Электронный билет')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (justCreated)
          Card(
            color: Colors.green.withValues(alpha: 0.15),
            child: const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Бронирование оформлено'),
              subtitle: Text('Покажите QR-код на входе в зал'),
            ),
          ),
        Card(
          elevation: 3,
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(cinemaName, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                const SizedBox(height: 4),
                Text(booking.movieTitle,
                    style: text.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _Field('Номер брони', booking.id, bold: true)),
                  StatusChip(status),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field('Дата', formatDay(booking.sessionStart))),
                  Expanded(child: _Field('Время', formatTime(booking.sessionStart))),
                  Expanded(child: _Field('Зал', '${booking.hall}')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field('Места', booking.seats.join(', '))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _Field('Покупатель', booking.customerName)),
                  Expanded(child: _Field('Итого', formatPrice(booking.total), bold: true)),
                ]),
                const Divider(height: 32),
                Opacity(
                  opacity: status == BookingStatus.cancelled ? 0.3 : 1,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: QrImageView(data: booking.qrPayload, size: 200, backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == BookingStatus.cancelled ? 'Билет аннулирован' : 'QR-код содержит номер брони и данные сеанса',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.info_outline),
          label: const Text('Детали и отмена бронирования'),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => BookingDetailsScreen(bookingId: booking.id))),
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.home_outlined),
          label: const Text('На главную'),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Field(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, style: text.bodyLarge?.copyWith(fontWeight: bold ? FontWeight.bold : null)),
    ]);
  }
}
