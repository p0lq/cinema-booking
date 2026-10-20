import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/seat.dart';
import '../models/session.dart';
import '../services/pricing.dart';
import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/price_summary.dart';
import 'e_ticket_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Session session;
  final Set<String> seats;
  final String? promoCode;

  const CheckoutScreen({super.key, required this.session, required this.seats, this.promoCode});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  PaymentMethod? _payment;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.session.isPast()) {
      _showError('Сеанс уже начался, бронирование невозможно');
      return;
    }
    setState(() => _submitting = true);

    if (_payment == PaymentMethod.card) {
      final paid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _FakePaymentDialog(amount: calculatePrice(widget.seats, promoCode: widget.promoCode).total),
      );
      if (paid != true) {
        setState(() => _submitting = false);
        return;
      }
    }
    if (!mounted) return;

    final provider = context.read<BookingProvider>();
    try {
      final booking = await provider.createBooking(
        session: widget.session,
        seats: widget.seats,
        customerName: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        paymentMethod: _payment!,
        promoCode: widget.promoCode,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ETicketScreen(bookingId: booking.id, justCreated: true)),
        (route) => route.isFirst,
      );
    } on SeatsUnavailableException catch (e) {
      setState(() => _submitting = false);
      _showError('Места ${e.seats.join(', ')} уже заняты. Вернитесь и выберите другие.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = calculatePrice(widget.seats, promoCode: widget.promoCode);
    final seats = widget.seats.toList()..sort(HallLayout.compare);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.session.movie.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${formatDay(widget.session.startsAt)}, ${widget.session.timeText} · зал ${widget.session.hall}'),
                const SizedBox(height: 4),
                Text('Места: ${seats.join(', ')}'),
                Text('Количество билетов: ${seats.length}'),
              ]),
            ),
          ),
          PriceSummary(price: price),
          const SizedBox(height: 16),
          Text('Данные покупателя', style: text.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ФИО *', prefixIcon: Icon(Icons.person_outline)),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: validateFullName,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
                labelText: 'Номер телефона *', hintText: '+7 700 123 45 67', prefixIcon: Icon(Icons.phone_outlined)),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: validatePhone,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: validateEmail,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: _payment,
            decoration: const InputDecoration(labelText: 'Способ оплаты *', prefixIcon: Icon(Icons.payments_outlined)),
            items: [
              for (final m in PaymentMethod.values) DropdownMenuItem(value: m, child: Text(m.label)),
            ],
            onChanged: (v) => setState(() => _payment = v),
            validator: (v) => v == null ? 'Выберите способ оплаты' : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Оплата учебная: реальные деньги не списываются, банковские данные не запрашиваются.',
            style: text.bodySmall,
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Подтвердить · ${formatPrice(price.total)}'),
          ),
        ),
      ),
    );
  }
}

/// Имитация оплаты картой: пауза, затем подтверждение.
class _FakePaymentDialog extends StatefulWidget {
  final int amount;
  const _FakePaymentDialog({required this.amount});

  @override
  State<_FakePaymentDialog> createState() => _FakePaymentDialogState();
}

class _FakePaymentDialogState extends State<_FakePaymentDialog> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оплата картой'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_done)
          const Icon(Icons.check_circle, color: Colors.green, size: 56)
        else
          const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
        const SizedBox(height: 12),
        Text(_done
            ? 'Платёж на ${formatPrice(widget.amount)} подтверждён (учебная имитация)'
            : 'Обработка платежа на ${formatPrice(widget.amount)}...'),
      ]),
      actions: [
        if (!_done) TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
        if (_done) FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Продолжить')),
      ],
    );
  }
}
