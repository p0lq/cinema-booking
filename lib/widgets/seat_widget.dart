import 'package:flutter/material.dart';

import '../models/seat.dart';

class SeatColors {
  static const free = Color(0xFF43A047);
  static const selected = Color(0xFF1E88E5);
  static const occupied = Color(0xFFE53935);
  static const vipBorder = Color(0xFFFFC107);

  static Color of(SeatState s) => switch (s) {
        SeatState.free => free,
        SeatState.selected => selected,
        SeatState.occupied => occupied,
      };
}

class SeatWidget extends StatelessWidget {
  final String seatId;
  final SeatState state;
  final double size;
  final VoidCallback onTap;

  const SeatWidget({
    super.key,
    required this.seatId,
    required this.state,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVip = HallLayout.categoryOf(seatId) == SeatCategory.vip;
    final color = SeatColors.of(state);
    return Tooltip(
      message: '$seatId · ${HallLayout.categoryOf(seatId).label} · ${switch (state) {
        SeatState.free => 'свободно',
        SeatState.selected => 'выбрано',
        SeatState.occupied => 'занято',
      }}',
      waitDuration: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: state == SeatState.selected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state == SeatState.occupied ? color.withValues(alpha: 0.75) : color,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.35),
                topRight: Radius.circular(size * 0.35),
                bottomLeft: Radius.circular(size * 0.12),
                bottomRight: Radius.circular(size * 0.12),
              ),
              border: isVip ? Border.all(color: SeatColors.vipBorder, width: 2) : null,
              boxShadow: state == SeatState.selected
                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                  : null,
            ),
            child: state == SeatState.occupied
                ? Icon(Icons.close, size: size * 0.55, color: Colors.white)
                : Text(
                    '${HallLayout.numberOf(seatId)}',
                    style: TextStyle(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}

class SeatLegend extends StatelessWidget {
  const SeatLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label, {bool vip = false}) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(4),
              border: vip ? Border.all(color: SeatColors.vipBorder, width: 2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ]);

    return Wrap(alignment: WrapAlignment.center, spacing: 16, runSpacing: 8, children: [
      item(SeatColors.free, 'Свободно'),
      item(SeatColors.selected, 'Выбрано'),
      item(SeatColors.occupied, 'Занято'),
      item(Colors.transparent, 'VIP (ряды G–H)', vip: true),
    ]);
  }
}
