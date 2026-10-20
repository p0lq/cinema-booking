import '../models/seat.dart';

class Promo {
  final String code;
  final int percent;
  final int minTickets;
  const Promo(this.code, this.percent, {this.minTickets = 1});
}

const promos = {
  'CINEMA10': Promo('CINEMA10', 10),
  'MOVIE20': Promo('MOVIE20', 20, minTickets: 4),
};

class PriceBreakdown {
  final int count;
  final int standardCount;
  final int vipCount;
  final int subtotal;
  final int discount;
  final String? appliedPromo;
  final String? promoError;

  const PriceBreakdown({
    required this.count,
    required this.standardCount,
    required this.vipCount,
    required this.subtotal,
    required this.discount,
    this.appliedPromo,
    this.promoError,
  });

  int get total => subtotal - discount;
}

/// Total = Σ SeatPrice − Discount.
/// Если промокод не подходит, скидка 0, а причина возвращается в promoError.
PriceBreakdown calculatePrice(Iterable<String> seats, {String? promoCode}) {
  var subtotal = 0;
  var vip = 0;
  for (final s in seats) {
    subtotal += HallLayout.priceOf(s);
    if (HallLayout.categoryOf(s) == SeatCategory.vip) vip++;
  }
  final count = seats.length;

  final code = promoCode?.trim().toUpperCase() ?? '';
  if (code.isEmpty) {
    return PriceBreakdown(count: count, standardCount: count - vip, vipCount: vip, subtotal: subtotal, discount: 0);
  }

  String? error;
  final promo = promos[code];
  if (promo == null) {
    error = 'Промокод «$code» не найден';
  } else if (count < promo.minTickets) {
    error = 'Промокод ${promo.code} действует при покупке от ${promo.minTickets} билетов';
  }

  final discount = error == null ? (subtotal * promo!.percent / 100).round() : 0;
  return PriceBreakdown(
    count: count,
    standardCount: count - vip,
    vipCount: vip,
    subtotal: subtotal,
    discount: discount,
    appliedPromo: error == null ? code : null,
    promoError: error,
  );
}
