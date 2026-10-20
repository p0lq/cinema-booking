import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import '../widgets/status_chip.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  Future<void> _cancel(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отменить бронирование?'),
        content: Text('Бронь ${booking.id} на «${booking.movieTitle}» будет отменена, '
            'места ${booking.seats.join(', ')} снова станут свободными.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<BookingProvider>().cancelBooking(booking.id);
      messenger.showSnackBar(const SnackBar(content: Text('Бронирование отменено')));
    } on StateError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>().bookingById(bookingId);
    if (booking == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Бронирование не найдено')));
    }
    final status = booking.effectiveStatus();

    Widget row(String label, String value) => ListTile(
          dense: true,
          title: Text(label),
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Детали бронирования')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Column(children: [
            ListTile(
              title: Text(booking.movieTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('№ ${booking.id}'),
              trailing: StatusChip(status),
            ),
            const Divider(height: 1),
            row('Сеанс', formatDateTime(booking.sessionStart)),
            row('Зал', '${booking.hall}'),
            row('Места', booking.seats.join(', ')),
            row('Количество билетов', '${booking.seats.length}'),
          ]),
        ),
        Card(
          child: Column(children: [
            row('ФИО', booking.customerName),
            row('Телефон', booking.phone),
            row('Email', booking.email),
            row('Способ оплаты', booking.paymentMethod.label),
            row('Оформлено', formatDateTime(booking.createdAt)),
          ]),
        ),
        Card(
          child: Column(children: [
            row('Стоимость до скидки', formatPrice(booking.subtotal)),
            row('Промокод', booking.promoCode ?? 'нет'),
            row('Скидка', formatPrice(booking.discount)),
            row('Итого', formatPrice(booking.total)),
          ]),
        ),
        const SizedBox(height: 12),
        if (status == BookingStatus.active)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Отменить бронирование'),
            onPressed: () => _cancel(context, booking),
          )
        else
          Text(
            status == BookingStatus.cancelled
                ? 'Бронирование отменено, повторная отмена недоступна.'
                : 'Сеанс уже прошёл, отмена недоступна.',
            textAlign: TextAlign.center,
          ),
      ]),
    );
  }
}
