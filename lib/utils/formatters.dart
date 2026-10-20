const _months = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

String _two(int v) => v.toString().padLeft(2, '0');

/// 12500 -> «12 500 ₸»
String formatPrice(int value) {
  final digits = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return '$buf ₸';
}

/// «20 окт, пн»
String formatDay(DateTime d) => '${d.day} ${_months[d.month - 1]}, ${_weekdays[d.weekday - 1]}';

String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// «20.10.2026 16:00»
String formatDateTime(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year} ${formatTime(d)}';

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
