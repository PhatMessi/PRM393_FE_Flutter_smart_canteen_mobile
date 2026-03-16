import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'providers/auth_provider.dart';
import 'services/local_notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/favorites_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/favorites_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initAndRequestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (context, auth, favorites) {
            favorites ??= FavoritesProvider();
            // Fire-and-forget: provider will notifyListeners when done.
            favorites.updateToken(auth.user?.token);
            return favorites;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Cang Tin Thong Minh',
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          // Màu xanh lá chủ đạo như trong hình
          primaryColor: const Color(0xFF1ED760),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1ED760),
            primary: const Color(0xFF1ED760),
          ),
          // Sử dụng Font Poppins cho hiện đại (hoặc DM Sans)
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          scaffoldBackgroundColor: const Color(
            0xFFF8F9FA,
          ), // Màu nền trắng xám nhẹ
        ),
        routes: {'/favorites': (_) => const FavoritesScreen()},
        home: const SplashScreen(),
      ),
    );
  }
}
