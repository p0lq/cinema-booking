import 'dart:convert';

import 'package:cinema_booking/main.dart';
import 'package:cinema_booking/models/booking.dart';
import 'package:cinema_booking/models/movie.dart';
import 'package:cinema_booking/models/seat.dart';
import 'package:cinema_booking/models/session.dart';
import 'package:cinema_booking/screens/booking_history_screen.dart';
import 'package:cinema_booking/screens/seat_selection_screen.dart';
import 'package:cinema_booking/services/pricing.dart';
import 'package:cinema_booking/services/storage_service.dart';
import 'package:cinema_booking/state/booking_provider.dart';
import 'package:cinema_booking/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _movie = Movie(
  id: 'm01',
  title: 'Последний рубеж',
  description: 'Описание',
  genre: 'Боевик',
  duration: 128,
  ageRating: '16+',
  poster: 'assets/posters/m01.png',
  rating: 7.9,
  hall: 1,
  sessions: ['12:00', '16:00', '20:00'],
);

const _movie2 = Movie(
  id: 'm02',
  title: 'Тихая гавань',
  description: 'Описание',
  genre: 'Драма',
  duration: 112,
  ageRating: '12+',
  poster: 'assets/posters/m02.png',
  rating: 8.3,
  hall: 2,
  sessions: ['12:00'],
);

Future<StorageService> _storage() async {
  SharedPreferences.setMockInitialValues({
    'movies': jsonEncode([_movie.toJson(), _movie2.toJson()]),
  });
  return StorageService.create();
}

Session _tomorrow(String time, [Movie movie = _movie]) {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day + 1);
  return Session.forDay(movie, day).firstWhere((s) => s.timeText == time);
}

Future<BookingProvider> _loadedProvider(StorageService storage) async {
  final p = BookingProvider(storage);
  await p.load();
  return p;
}

Future<Booking> _book(BookingProvider p, Session s, Set<String> seats, {String? promo}) => p.createBooking(
      session: s,
      seats: seats,
      customerName: 'Иванов Иван',
      phone: '+7 700 123 45 67',
      email: 'ivan@mail.kz',
      paymentMethod: PaymentMethod.cashier,
      promoCode: promo,
    );

void main() {
  group('Схема зала', () {
    test('8 рядов по 10 мест, уникальные идентификаторы A1..H10', () {
      final ids = HallLayout.allSeatIds;
      expect(ids.length, 80);
      expect(ids.toSet().length, 80);
      expect(ids.first, 'A1');
      expect(ids.last, 'H10');
    });

    test('ряды A–F стандартные, G–H VIP', () {
      expect(HallLayout.priceOf('A1'), 2500);
      expect(HallLayout.priceOf('F10'), 2500);
      expect(HallLayout.priceOf('G1'), 4000);
      expect(HallLayout.priceOf('H10'), 4000);
    });

    test('сортировка мест A2 < A10 < B1', () {
      final list = ['B1', 'A10', 'A2']..sort(HallLayout.compare);
      expect(list, ['A2', 'A10', 'B1']);
    });
  });

  group('Расчёт стоимости', () {
    test('стандартные и VIP места без скидки', () {
      final p = calculatePrice({'A1', 'A2', 'H5'});
      expect(p.count, 3);
      expect(p.subtotal, 2500 * 2 + 4000);
      expect(p.discount, 0);
      expect(p.total, 9000);
    });

    test('CINEMA10 даёт 10%', () {
      final p = calculatePrice({'A1', 'G1'}, promoCode: 'cinema10');
      expect(p.appliedPromo, 'CINEMA10');
      expect(p.discount, 650);
      expect(p.total, 5850);
    });

    test('MOVIE20 требует минимум 4 билета', () {
      final three = calculatePrice({'A1', 'A2', 'A3'}, promoCode: 'MOVIE20');
      expect(three.discount, 0);
      expect(three.promoError, isNotNull);

      final four = calculatePrice({'A1', 'A2', 'A3', 'A4'}, promoCode: 'MOVIE20');
      expect(four.promoError, isNull);
      expect(four.discount, 2000);
      expect(four.total, 8000);
    });

    test('неизвестный промокод не даёт скидку и возвращает ошибку', () {
      final p = calculatePrice({'A1'}, promoCode: 'FREE100');
      expect(p.discount, 0);
      expect(p.promoError, contains('не найден'));
    });
  });

  group('Проверка формы', () {
    test('ФИО', () {
      expect(validateFullName(''), isNotNull);
      expect(validateFullName('Иван'), isNotNull);
      expect(validateFullName('Иванов Иван'), isNull);
    });

    test('телефон', () {
      expect(validatePhone(''), isNotNull);
      expect(validatePhone('12345'), isNotNull);
      expect(validatePhone('+7 (700) 123-45-67'), isNull);
    });

    test('email', () {
      expect(validateEmail('ivan@'), isNotNull);
      expect(validateEmail('ivan.mail.kz'), isNotNull);
      expect(validateEmail('ivan@mail.kz'), isNull);
    });
  });

  group('Бронирование', () {
    test('бронь занимает места, повторно их занять нельзя', () async {
      final p = await _loadedProvider(await _storage());
      final s = _tomorrow('16:00');
      final free = HallLayout.allSeatIds.where((id) => !p.occupiedFor(s).contains(id)).take(2).toSet();

      final booking = await _book(p, s, free);
      expect(booking.id, startsWith('CB-'));
      expect(p.occupiedFor(s), containsAll(free));
      expect(() => _book(p, s, {free.first}), throwsA(isA<SeatsUnavailableException>()));
    });

    test('места независимы для разных сеансов', () async {
      final p = await _loadedProvider(await _storage());
      final s1 = _tomorrow('12:00');
      final s2 = _tomorrow('20:00');
      final seat = HallLayout.allSeatIds
          .firstWhere((id) => !p.occupiedFor(s1).contains(id) && !p.occupiedFor(s2).contains(id));

      await _book(p, s1, {seat});
      expect(p.occupiedFor(s1), contains(seat));
      expect(p.occupiedFor(s2), isNot(contains(seat)));
    });

    test('отмена освобождает места и сохраняет бронь в истории', () async {
      final p = await _loadedProvider(await _storage());
      final s = _tomorrow('12:00');
      final seat = HallLayout.allSeatIds.firstWhere((id) => !p.occupiedFor(s).contains(id));
      final booking = await _book(p, s, {seat});

      await p.cancelBooking(booking.id);
      expect(p.occupiedFor(s), isNot(contains(seat)));
      expect(p.bookingById(booking.id)!.status, BookingStatus.cancelled);
      expect(p.bookings.length, 1);
      expect(() => p.cancelBooking(booking.id), throwsStateError);
    });

    test('данные сохраняются после перезапуска', () async {
      final storage = await _storage();
      final p1 = await _loadedProvider(storage);
      final s = _tomorrow('20:00');
      final seat = HallLayout.allSeatIds.firstWhere((id) => !p1.occupiedFor(s).contains(id));
      final booking = await _book(p1, s, {seat}, promo: 'CINEMA10');

      final p2 = await _loadedProvider(StorageService(await SharedPreferences.getInstance()));
      final restored = p2.bookingById(booking.id)!;
      expect(restored.total, booking.total);
      expect(restored.promoCode, 'CINEMA10');
      expect(p2.occupiedFor(s), contains(seat));
    });

    test('прошедший сеанс нельзя забронировать', () async {
      final p = await _loadedProvider(await _storage());
      final now = DateTime.now();
      final past = Session(movie: _movie, startsAt: now.subtract(const Duration(hours: 1)));
      expect(() => _book(p, past, {'A1'}), throwsStateError);
    });

    test('бронь на прошедший сеанс считается завершённой', () {
      final b = Booking.fromJson({
        'id': 'CB-1', 'movieId': 'm01', 'movieTitle': 't', 'sessionId': 's',
        'sessionStart': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'hall': 1, 'seats': ['A1'], 'customerName': 'a', 'phone': 'p', 'email': 'e',
        'paymentMethod': 'card', 'subtotal': 2500, 'discount': 0, 'total': 2500, 'promoCode': null,
        'createdAt': DateTime.now().toIso8601String(), 'status': 'active',
      });
      expect(b.effectiveStatus(), BookingStatus.completed);
      expect(b.canCancel(), isFalse);
    });
  });

  testWidgets('главный экран: каталог и поиск', (tester) async {
    final storage = await _storage();
    await tester.pumpWidget(CinemaBookingApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Кинотеатр «Звезда»'), findsOneWidget);
    expect(find.text('Последний рубеж'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'гавань');
    await tester.pumpAndSettle();
    expect(find.text('Последний рубеж'), findsNothing);
    expect(find.text('Тихая гавань'), findsWidgets);
  });

  testWidgets('выбор и отмена выбора места на схеме', (tester) async {
    final storage = await _storage();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(CinemaBookingApp(storage: storage));
    await tester.pumpAndSettle();

    final provider = Provider.of<BookingProvider>(tester.element(find.byType(Scaffold).first), listen: false);
    final s = _tomorrow('16:00');
    final seat = HallLayout.allSeatIds.firstWhere((id) => !provider.occupiedFor(s).contains(id));

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute(builder: (_) => SeatSelectionScreen(session: s)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey(seat)));
    await tester.pumpAndSettle();
    expect(find.text('Выбранные места (1)'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey(seat)));
    await tester.pumpAndSettle();
    expect(find.text('Выбранные места (0)'), findsOneWidget);
  });

  testWidgets('история -> билет с QR -> детали -> отмена через диалог', (tester) async {
    final storage = await _storage();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(CinemaBookingApp(storage: storage));
    await tester.pumpAndSettle();
    final provider = Provider.of<BookingProvider>(tester.element(find.byType(Scaffold).first), listen: false);
    final s = _tomorrow('12:00');
    final seat = HallLayout.allSeatIds.firstWhere((id) => !provider.occupiedFor(s).contains(id));
    late Booking booking;
    await tester.runAsync(() async => booking = await _book(provider, s, {seat}));

    tester.state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute(builder: (_) => const BookingHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('№ ${booking.id}'), findsOneWidget);
    expect(find.text('Активное'), findsOneWidget);

    await tester.tap(find.text('№ ${booking.id}'));
    await tester.pumpAndSettle();
    expect(find.text('Электронный билет'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('Детали и отмена бронирования'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить бронирование'));
    await tester.pumpAndSettle();
    expect(find.text('Отменить бронирование?'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Да, отменить'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Отменённое'), findsOneWidget);
    expect(find.text('Отменить бронирование'), findsNothing);
    expect(provider.occupiedFor(s), isNot(contains(seat)));
  });
}
