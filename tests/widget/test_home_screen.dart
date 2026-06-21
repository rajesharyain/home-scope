import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homescope/screens/home/home_screen.dart';
import 'package:homescope/config/app_theme.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    Widget buildTestApp() => ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const HomeScreen(),
          ),
        );

    testWidgets('shows app title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      expect(find.text('HomeScope'), findsOneWidget);
    });

    testWidgets('shows address input field', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows Analyze Address button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      expect(find.text('Analyze Address'), findsOneWidget);
    });

    testWidgets('shows Advanced button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();
      expect(find.text('Advanced'), findsOneWidget);
    });

    testWidgets('validates empty address submission', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump();

      await tester.tap(find.text('Analyze Address'));
      await tester.pump();

      expect(find.text('Address is required'), findsOneWidget);
    });
  });
}
