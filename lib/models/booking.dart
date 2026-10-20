enum BookingStatus {
  active('Активное'),
  completed('Завершённое'),
  cancelled('Отменённое');

  final String label;
  const BookingStatus(this.label);
}

enum PaymentMethod {
  card('Банковская карта'),
  cashier('Оплата в кассе кинотеатра');

  final String label;
  const PaymentMethod(this.label);
}

class Booking {
  final String id;
  final String movieId;
  final String movieTitle;
  final String sessionId;
  final DateTime sessionStart;
  final int hall;
  final List<String> seats;
  final String customerName;
  final String phone;
  final String email;
  final PaymentMethod paymentMethod;
  final int subtotal;
  final int discount;
  final int total;
  final String? promoCode;
  final DateTime createdAt;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.movieId,
    required this.movieTitle,
    required this.sessionId,
    required this.sessionStart,
    required this.hall,
    required this.seats,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.paymentMethod,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.promoCode,
    required this.createdAt,
    required this.status,
  });

  /// Активная бронь на прошедший сеанс показывается как завершённая.
  BookingStatus effectiveStatus([DateTime? now]) {
    if (status == BookingStatus.active && !sessionStart.isAfter(now ?? DateTime.now())) {
      return BookingStatus.completed;
    }
    return status;
  }

  bool canCancel([DateTime? now]) => effectiveStatus(now) == BookingStatus.active;

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        movieId: movieId,
        movieTitle: movieTitle,
        sessionId: sessionId,
        sessionStart: sessionStart,
        hall: hall,
        seats: seats,
        customerName: customerName,
        phone: phone,
        email: email,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        discount: discount,
        total: total,
        promoCode: promoCode,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  /// Содержимое QR-кода: номер брони и ключевые данные билета.
  String get qrPayload =>
      'CINEMA-BOOKING|$id|$movieTitle|${sessionStart.toIso8601String()}|hall:$hall|seats:${seats.join(',')}';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        movieId: json['movieId'] as String,
        movieTitle: json['movieTitle'] as String,
        sessionId: json['sessionId'] as String,
        sessionStart: DateTime.parse(json['sessionStart'] as String),
        hall: json['hall'] as int,
        seats: List<String>.from(json['seats'] as List),
        customerName: json['customerName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
        subtotal: json['subtotal'] as int,
        discount: json['discount'] as int,
        total: json['total'] as int,
        promoCode: json['promoCode'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: BookingStatus.values.byName(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'movieId': movieId,
        'movieTitle': movieTitle,
        'sessionId': sessionId,
        'sessionStart': sessionStart.toIso8601String(),
        'hall': hall,
        'seats': seats,
        'customerName': customerName,
        'phone': phone,
        'email': email,
        'paymentMethod': paymentMethod.name,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'promoCode': promoCode,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };
}
