enum SeatState { free, selected, occupied }

enum SeatCategory {
  standard('Стандартный', 2500),
  vip('VIP', 4000);

  final String label;
  final int price;
  const SeatCategory(this.label, this.price);
}

class HallLayout {
  static const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
  static const seatsPerRow = 10;
  static const vipRows = {'G', 'H'};

  static int get totalSeats => rows.length * seatsPerRow;

  static String seatId(String row, int number) => '$row$number';

  static List<String> get allSeatIds => [
        for (final r in rows)
          for (var n = 1; n <= seatsPerRow; n++) seatId(r, n),
      ];

  static String rowOf(String seatId) => seatId.substring(0, 1);

  static int numberOf(String seatId) => int.parse(seatId.substring(1));

  static SeatCategory categoryOf(String seatId) =>
      vipRows.contains(rowOf(seatId)) ? SeatCategory.vip : SeatCategory.standard;

  static int priceOf(String seatId) => categoryOf(seatId).price;

  /// Сортировка A1, A2 ... A10, B1 вместо строковой A1, A10, A2.
  static int compare(String a, String b) {
    final byRow = rows.indexOf(rowOf(a)).compareTo(rows.indexOf(rowOf(b)));
    return byRow != 0 ? byRow : numberOf(a).compareTo(numberOf(b));
  }
}
