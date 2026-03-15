// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_canteen_mobile/main.dart';
import 'package:smart_canteen_mobile/screens/login_screen.dart';

void main() {
  testWidgets('App boots and navigates to Login when no token', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Splash shows a loading indicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // After splash delay, without token it should navigate to LoginScreen.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
