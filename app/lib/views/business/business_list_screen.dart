// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import 'create_edit_business_screen.dart';

/**
 * Screen presenting a list of businesses registered by the active user.
 *
 * <p>Connects to {@link BusinessProvider} to perform CRUD transactions and
 * automatically pulls the active JWT session token from {@link AuthService}.</p>
 */
class BusinessListScreen extends StatefulWidget {
  const BusinessListScreen({super.key});

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    // Load caller's businesses on screen initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final token = context.read<AuthService>().token;
    if (token != null) {
      context.read<BusinessProvider>().fetchMyBusinesses(token);
    }
  }

  Future<void> _delete(Business business) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Business'),
        content: Text('Are you sure you want to delete "${business.name}"? This will permanently remove all associated rental units.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = context.read<AuthService>().token;
      if (token != null) {
        try {
          await context.read<BusinessProvider>().deleteBusiness(business.id, token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business profile deleted successfully')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BusinessProvider>();
    final list = provider.myBusinesses;
    final isLoading = provider.isLoading;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Businesses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading && list.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Global error banner
                  if (errorMessage != null && list.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.redAccent.withOpacity(0.1),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  Expanded(
                    child: list.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final item = list[index];
                              return _buildBusinessCard(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D5FEF),
        foregroundColor: Colors.white,
        tooltip: 'Add Business',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditBusinessScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No businesses registered yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'List your portable toilets or cold rooms business profile to start renting out units.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEditBusinessScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Register Business'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(Business business) {
    final typeLabel = business.businessType == BusinessType.TOILET_RENTAL
        ? 'Toilet Hire'
        : 'Cold Storage';

    final badgeColor = business.businessType == BusinessType.TOILET_RENTAL
        ? const Color(0xFF5D5FEF).withOpacity(0.15)
        : const Color(0xFFFFB74D).withOpacity(0.15);

    final badgeTextColor = business.businessType == BusinessType.TOILET_RENTAL
        ? const Color(0xFF8C8DFF)
        : const Color(0xFFFFCC80);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dashboard for "${business.name}" coming soon!')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Edit / Delete Actions Dropdown
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateEditBusinessScreen(business: business),
                          ),
                        );
                      } else if (value == 'delete') {
                        _delete(business);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                business.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              if (business.description != null && business.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  business.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      business.address,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    business.phoneNumber,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
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
