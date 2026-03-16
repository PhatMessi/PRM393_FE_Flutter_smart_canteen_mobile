import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
<<<<<<< HEAD
import 'screens/favorites_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/favorites_provider.dart';
=======
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8

void main() {
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
<<<<<<< HEAD
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (_) => FavoritesProvider(),
          update: (context, auth, favorites) {
            favorites ??= FavoritesProvider();
            // Fire-and-forget: provider will notifyListeners when done.
            favorites.updateToken(auth.user?.token);
            return favorites;
          },
        ),
=======
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
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
<<<<<<< HEAD
          primaryColor: const Color(0xFF1ED760),
=======
          primaryColor: const Color(0xFF1ED760), 
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1ED760),
            primary: const Color(0xFF1ED760),
          ),
          // Sử dụng Font Poppins cho hiện đại (hoặc DM Sans)
<<<<<<< HEAD
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          scaffoldBackgroundColor: const Color(
            0xFFF8F9FA,
          ), // Màu nền trắng xám nhẹ
        ),
        routes: {'/favorites': (_) => const FavoritesScreen()},
=======
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Màu nền trắng xám nhẹ
        ),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
        home: const SplashScreen(),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
