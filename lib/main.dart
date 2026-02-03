import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';

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
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fresh Bites',
        theme: ThemeData(
          useMaterial3: true,
          // Màu xanh lá chủ đạo như trong hình
          primaryColor: const Color(0xFF1ED760), 
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1ED760),
            primary: const Color(0xFF1ED760),
          ),
          // Sử dụng Font Poppins cho hiện đại (hoặc DM Sans)
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Màu nền trắng xám nhẹ
        ),
        home: const SplashScreen(),
      ),
    );
  }
}