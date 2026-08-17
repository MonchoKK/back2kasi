// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';

/**
 * Screen presenting a listing of available rental units in the user's area.
 *
 * <p>Exposes search and filter controls, and connects to {@link AuthService} to logout.</p>
 */
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userEmail = authService.userEmail ?? 'User';

    // Mock premium units to make the stub look production-grade
    final List<Map<String, dynamic>> mockUnits = [
      {
        'name': 'VIP Toilet Unit 4',
        'type': 'VIP Toilet',
        'price': 'R 250.00 / day',
        'capacity': '1 Person',
        'description': 'Luxury flushing portable toilet with solar lights & mirror.',
        'icon': Icons.wc,
      },
      {
        'name': 'Mobile Cold Room Large',
        'type': 'Mobile Cold Room',
        'price': 'R 850.00 / day',
        'capacity': '1500 Liters',
        'description': 'Trailer-mounted cold storage, ideal for township events & catering.',
        'icon': Icons.ac_unit,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Rentals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Greetings
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              userEmail,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF5D5FEF),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Search Bar Placeholder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161524),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 12),
                  Text('Search for units near you...', style: TextStyle(color: Colors.grey)),
                  Spacer(),
                  Icon(Icons.tune, color: Color(0xFF5D5FEF)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Recommended Rentals',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            // Listings List View
            Expanded(
              child: ListView.builder(
                itemCount: mockUnits.length,
                itemBuilder: (context, index) {
                  final item = mockUnits[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF5D5FEF).withOpacity(0.1),
                                child: Icon(item['icon'] as IconData, color: const Color(0xFF5D5FEF)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                                    ),
                                    Text(
                                      item['type'] as String,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item['price'] as String,
                                style: const TextStyle(
                                  color: Color(0xFFFFB74D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Capacity: ${item['capacity']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking flow coming soon!')),
                                  );
                                },
                                child: const Text('Book Now'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
