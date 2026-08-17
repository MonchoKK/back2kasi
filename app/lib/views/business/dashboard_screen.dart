// ignore_for_file: slash_for_doc_comments
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';

/**
 * Screen presenting the Business Owner Dashboard interface.
 *
 * <p>Exposes controls to manage business registration profiles and rental listings.</p>
 */
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.dashboard_customize_outlined,
              size: 72,
              color: Color(0xFFFFB74D),
            ),
            const SizedBox(height: 24),
            Text(
              'Business Owner Portal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Manage your businesses, register units, and track active client bookings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business Registration coming in future sprint!')),
                );
              },
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Register Business'),
            ),
          ],
        ),
      ),
    );
  }
}
