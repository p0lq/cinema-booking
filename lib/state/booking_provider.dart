import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/movie.dart';
import '../models/seat.dart';
import '../models/session.dart';
import '../services/movie_repository.dart';
import '../services/pricing.dart';
import '../services/storage_service.dart';

class SeatsUnavailableException implements Exception {
  final List<String> seats;
  SeatsUnavailableException(this.seats);

  @override
  String toString() => 'Места уже заняты: ${seats.join(', ')}';
}

class BookingProvider extends ChangeNotifier {
  final StorageService storage;
  final MovieRepository repository;
  final Random _random;

  BookingProvider(this.storage, {MovieRepository? repository, Random? random})
      : repository = repository ?? MovieRepository(storage),
        _random = random ?? Random();

  List<Movie> _movies = [];
  Map<String, Set<String>> _occupied = {};
  List<Booking> _bookings = [];
  bool _loading = true;
  String? _error;

  List<Movie> get movies => List.unmodifiable(_movies);
  bool get loading => _loading;
  String? get error => _error;

  /// Новые брони сверху.
  List<Booking> get bookings => List.of(_bookings)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<String> get genres => (_movies.map((m) => m.genre).toSet().toList()..sort());

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _movies = await repository.loadMovies();
      _occupied = storage.loadOccupied();
      _bookings = storage.loadBookings();
    } on FormatException catch (e) {
      _error = 'Не удалось прочитать данные: ${e.message}';
    } on FlutterError catch (e) {
      _error = 'Не удалось загрузить каталог: ${e.message}';
    }
    _loading = false;
    notifyListeners();
  }

  Movie? movieById(String id) {
    for (final m in _movies) {
      if (m.id == id) return m;
    }
    return null;
  }

  Booking? bookingById(String id) {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Занятые места сеанса. При первом обращении к сеансу часть мест
  /// помечается занятыми, чтобы имитировать покупки других зрителей.
  Set<String> occupiedFor(Session session) {
    final existing = _occupied[session.id];
    if (existing != null) return Set.unmodifiable(existing);

    final seeded = _seedOccupied(session.id);
    _occupied[session.id] = seeded;
    storage.saveOccupied(_occupied);
    return Set.unmodifiable(seeded);
  }

  int freeSeatsCount(Session session) => HallLayout.totalSeats - occupiedFor(session).length;

  Set<String> _seedOccupied(String sessionId) {
    final rnd = Random(sessionId.codeUnits.fold<int>(7, (h, c) => (h * 31 + c) & 0x7fffffff));
    final all = HallLayout.allSeatIds..shuffle(rnd);
    return all.take(6 + rnd.nextInt(14)).toSet();
  }

  Future<Booking> createBooking({
    required Session session,
    required Set<String> seats,
    required String customerName,
    required String phone,
    required String email,
    required PaymentMethod paymentMethod,
    String? promoCode,
  }) async {
    if (seats.isEmpty) throw ArgumentError('Не выбрано ни одного места');
    if (session.isPast()) throw StateError('Сеанс уже начался');

    final occupied = _occupied.putIfAbsent(session.id, () => _seedOccupied(session.id));
    final conflicts = seats.where(occupied.contains).toList();
    if (conflicts.isNotEmpty) throw SeatsUnavailableException(conflicts);

    final price = calculatePrice(seats, promoCode: promoCode);
    final sortedSeats = seats.toList()..sort(HallLayout.compare);
    final booking = Booking(
      id: _newBookingId(),
      movieId: session.movie.id,
      movieTitle: session.movie.title,
      sessionId: session.id,
      sessionStart: session.startsAt,
      hall: session.hall,
      seats: sortedSeats,
      customerName: customerName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      paymentMethod: paymentMethod,
      subtotal: price.subtotal,
      discount: price.discount,
      total: price.total,
      promoCode: price.appliedPromo,
      createdAt: DateTime.now(),
      status: BookingStatus.active,
    );

    occupied.addAll(seats);
    _bookings.add(booking);
    await storage.saveOccupied(_occupied);
    await storage.saveBookings(_bookings);
    notifyListeners();
    return booking;
  }

  Future<void> cancelBooking(String bookingId) async {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) throw StateError('Бронирование $bookingId не найдено');
    final booking = _bookings[index];
    if (!booking.canCancel()) throw StateError('Это бронирование нельзя отменить');

    _bookings[index] = booking.copyWith(status: BookingStatus.cancelled);
    _occupied[booking.sessionId]?.removeAll(booking.seats);
    await storage.saveOccupied(_occupied);
    await storage.saveBookings(_bookings);
    notifyListeners();
  }

  String _newBookingId() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now();
    final date = '${now.year % 100}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    String id;
    do {
      final suffix = List.generate(5, (_) => alphabet[_random.nextInt(alphabet.length)]).join();
      id = 'CB-$date-$suffix';
    } while (bookingById(id) != null);
    return id;
  }
}
