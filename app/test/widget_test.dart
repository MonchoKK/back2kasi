import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:back2kasi_app/main.dart';
import 'package:back2kasi_app/core/auth_service.dart';

// Test double for AuthService to avoid secure storage channel hang in widget tests
class MockAuthService extends AuthService {
  bool _mockLoading = true;

  @override
  bool get isLoading => _mockLoading;

  @override
  bool get isAuthenticated => false;

  void setMockLoading(bool val) {
    _mockLoading = val;
    notifyListeners();
  }
}

void main() {
  testWidgets('App smoke test - renders initial loading or login screen', (WidgetTester tester) async {
    final mockAuth = MockAuthService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuth),
        ],
        child: const Back2KasiApp(),
      ),
    );

    // Initial frame triggers loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Disable loading state to simulate auto-login check finished
    mockAuth.setMockLoading(false);
    await tester.pumpAndSettle();

    // Verify it settled on the Login screen
    expect(find.text('Back2Kasi'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
