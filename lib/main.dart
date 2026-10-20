import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'state/booking_provider.dart';
import 'state/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.create();
  runApp(CinemaBookingApp(storage: storage));
}

class CinemaBookingApp extends StatelessWidget {
  final StorageService storage;
  const CinemaBookingApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingProvider(storage)..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Cinema Booking',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const HomeScreen(),
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) => ThemeData(
        colorSchemeSeed: const Color(0xFF6A1B9A),
        brightness: brightness,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      );
}
