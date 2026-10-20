import 'package:flutter/material.dart';

import '../models/seat.dart';
import '../services/pricing.dart';
import '../utils/formatters.dart';

class PriceSummary extends StatelessWidget {
  final PriceBreakdown price;
  const PriceSummary({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget line(String label, String value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          line('Билетов', '${price.count}'),
          if (price.standardCount > 0)
            line('Стандарт × ${price.standardCount}', formatPrice(price.standardCount * SeatCategory.standard.price)),
          if (price.vipCount > 0) line('VIP × ${price.vipCount}', formatPrice(price.vipCount * SeatCategory.vip.price)),
          line('Стоимость до скидки', formatPrice(price.subtotal)),
          line('Скидка${price.appliedPromo != null ? ' (${price.appliedPromo})' : ''}',
              price.discount > 0 ? '−${formatPrice(price.discount)}' : formatPrice(0)),
          const Divider(),
          line('Итого', formatPrice(price.total), style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
