import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:back2kasi_app/main.dart';
import 'package:back2kasi_app/core/auth_service.dart';

void main() {
  testWidgets('App smoke test - renders initial loading or login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const Back2KasiApp(),
      ),
    );

    // Initial frame triggers loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Let the timer or auto-login microtasks complete
    await tester.pumpAndSettle();

    // Verify it settled on either the Login screen or loading state
    expect(find.text('Back2Kasi'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
