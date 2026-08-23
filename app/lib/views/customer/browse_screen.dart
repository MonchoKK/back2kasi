// ignore_for_file: slash_for_doc_comments, deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import 'customer_business_detail_screen.dart';

/**
 * Screen presenting a listing of registered township businesses.
 *
 * <p>Calls the GET /api/v1/businesses endpoint (JWT required) and
 * displays all businesses. Each business card has a tap action that
 * navigates to CustomerBusinessDetailScreen.</p>
 */
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBusinesses();
    });
  }

  void _loadBusinesses() {
    final token = context.read<AuthService>().token;
    if (token != null) {
      context.read<BusinessProvider>().fetchAllBusinesses(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userEmail = authService.userEmail ?? 'User';
    final provider = context.watch<BusinessProvider>();
    final businesses = provider.allBusinesses;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBusinesses,
          ),
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
                  Text('Search for services near you...', style: TextStyle(color: Colors.grey)),
                  Spacer(),
                  Icon(Icons.tune, color: Color(0xFF5D5FEF)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header with Count
            Row(
              children: [
                Text(
                  'Local Providers',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const SizedBox(width: 8),
                if (!isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D5FEF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${businesses.length}',
                      style: const TextStyle(
                        color: Color(0xFF8C8DFF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Error banner
            if (errorMessage != null && businesses.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),

            // Listings
            Expanded(
              child: isLoading && businesses.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async => _loadBusinesses(),
                      child: businesses.isEmpty
                          ? _buildEmptyState(errorMessage)
                          : ListView.builder(
                              itemCount: businesses.length,
                              itemBuilder: (context, index) {
                                return _buildBusinessCard(businesses[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String? errorMessage) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              errorMessage != null ? Icons.wifi_off : Icons.storefront_outlined,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage != null ? 'Unable to load services' : 'No service providers yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Be the first to list a business or check back later!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBusinesses,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    // Pick icon and display details
    IconData businessIcon;
    String typeLabel;
    
    if (business.businessType == BusinessType.COLD_ROOM_RENTAL) {
      businessIcon = Icons.ac_unit;
      typeLabel = 'Cold Storage Provider';
    } else {
      businessIcon = Icons.wc;
      typeLabel = 'Toilet Rental Agency';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerBusinessDetailScreen(business: business),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF5D5FEF).withOpacity(0.1),
                    child: Icon(businessIcon, color: const Color(0xFF5D5FEF)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                        ),
                        Text(
                          typeLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF8C8DFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (business.description != null && business.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  business.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      business.address,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
