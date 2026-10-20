import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/seat.dart';
import '../models/session.dart';
import '../services/pricing.dart';
import '../state/booking_provider.dart';
import '../utils/formatters.dart';
import '../widgets/price_summary.dart';
import '../widgets/seat_widget.dart';
import 'checkout_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final Session session;
  const SeatSelectionScreen({super.key, required this.session});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<String> _selected = {};
  final _promoController = TextEditingController();
  String? _promoCode;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _toggle(String seatId, Set<String> occupied) {
    if (occupied.contains(seatId)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Место $seatId уже занято'), duration: const Duration(seconds: 1)));
      return;
    }
    setState(() {
      if (!_selected.remove(seatId)) _selected.add(seatId);
    });
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    FocusScope.of(context).unfocus();
    if (code.isEmpty) {
      setState(() => _promoCode = null);
      return;
    }
    final result = calculatePrice(_selected, promoCode: code);
    setState(() => _promoCode = code);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(result.promoError ?? 'Промокод $code применён'),
        backgroundColor: result.promoError != null ? Theme.of(context).colorScheme.error : null,
      ));
  }

  void _removePromo() {
    _promoController.clear();
    setState(() => _promoCode = null);
  }

  Future<void> _proceed() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Выберите хотя бы одно место')));
      return;
    }
    final price = calculatePrice(_selected, promoCode: _promoCode);
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        session: widget.session,
        seats: Set.of(_selected),
        promoCode: price.appliedPromo,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final occupied = provider.occupiedFor(widget.session);
    // Если место заняли, пока пользователь был на другом экране, снимаем выбор.
    _selected.removeWhere(occupied.contains);

    final price = calculatePrice(_selected, promoCode: _promoCode);
    final text = Theme.of(context).textTheme;
    final sortedSelected = _selected.toList()..sort(HallLayout.compare);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.session.movie.title),
          Text('${formatDay(widget.session.startsAt)}, ${widget.session.timeText} · зал ${widget.session.hall}',
              style: const TextStyle(fontSize: 13)),
        ]),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(12, 16, 12, 24), children: [
        _ScreenArc(),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, constraints) {
          const labelWidth = 22.0;
          const spacing = 4.0;
          const aisle = 14.0;
          final perRow = HallLayout.seatsPerRow;
          final seatSize = min(36.0,
              (constraints.maxWidth - 2 * labelWidth - aisle - spacing * (perRow - 1) - 8) / perRow);
          return Column(children: [
            for (final row in HallLayout.rows)
              Padding(
                padding: EdgeInsets.only(bottom: spacing + 2, top: row == 'G' ? 10 : 0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: labelWidth, child: Text(row, style: text.labelLarge)),
                  for (var n = 1; n <= perRow; n++) ...[
                    if (n > 1) SizedBox(width: n == perRow ~/ 2 + 1 ? aisle : spacing),
                    Builder(builder: (_) {
                      final id = HallLayout.seatId(row, n);
                      final state = occupied.contains(id)
                          ? SeatState.occupied
                          : (_selected.contains(id) ? SeatState.selected : SeatState.free);
                      return SeatWidget(
                        key: ValueKey(id),
                        seatId: id,
                        state: state,
                        size: seatSize,
                        onTap: () => _toggle(id, occupied),
                      );
                    }),
                  ],
                  SizedBox(width: labelWidth, child: Text(row, textAlign: TextAlign.right, style: text.labelLarge)),
                ]),
              ),
          ]);
        }),
        const SizedBox(height: 12),
        const SeatLegend(),
        const SizedBox(height: 8),
        Text(
          'Стандарт (A–F): ${formatPrice(SeatCategory.standard.price)} · VIP (G–H): ${formatPrice(SeatCategory.vip.price)}',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const Divider(height: 32),
        Text('Выбранные места (${_selected.length})', style: text.titleMedium),
        const SizedBox(height: 8),
        if (_selected.isEmpty)
          const Text('Нажмите на свободное место на схеме')
        else
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final id in sortedSelected)
              InputChip(
                label: Text('$id · ${formatPrice(HallLayout.priceOf(id))}'),
                avatar: HallLayout.categoryOf(id) == SeatCategory.vip ? const Icon(Icons.star, size: 16) : null,
                onDeleted: () => setState(() => _selected.remove(id)),
              ),
          ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Промокод', isDense: true, hintText: 'CINEMA10'),
              onSubmitted: (_) => _applyPromo(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(onPressed: _applyPromo, child: const Text('Применить')),
        ]),
        if (_promoCode != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(price.promoError == null ? Icons.check_circle : Icons.error_outline,
                size: 18, color: price.promoError == null ? Colors.green : Theme.of(context).colorScheme.error),
            const SizedBox(width: 6),
            Expanded(child: Text(price.promoError ?? 'Применён промокод ${price.appliedPromo}')),
            TextButton(onPressed: _removePromo, child: const Text('Убрать')),
          ]),
        ],
        const SizedBox(height: 12),
        PriceSummary(price: price),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _proceed,
            child: Text(_selected.isEmpty
                ? 'Выберите места'
                : 'Оформить · ${formatPrice(price.total)}'),
          ),
        ),
      ),
    );
  }
}

class _ScreenArc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(children: [
      CustomPaint(size: const Size(double.infinity, 24), painter: _ArcPainter(color)),
      Text('ЭКРАН', style: TextStyle(letterSpacing: 6, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height)
      ..quadraticBezierTo(size.width / 2, 0, size.width * 0.92, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}
