// ignore_for_file: slash_for_doc_comments, use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../core/auth_service.dart';
import '../../core/business_provider.dart';
import '../../models/business.dart';
import '../shared/components/bk_components.dart';
import 'business_detail_screen.dart';
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
        content: Text(
          'Are you sure you want to delete "${business.name}"? This will permanently remove all associated rental units.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
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
            const SnackBar(
              content: Text('Business profile deleted successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.errorColor,
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: BkAppBar(
        title: 'My Businesses',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.darkTextColor),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading && list.isEmpty
          ? const BkLoadingIndicator(message: 'Loading your businesses...')
          : RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () async => _loadData(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Global error banner
                  if (errorMessage != null && list.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppTheme.errorColor.withOpacity(0.08),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  Expanded(
                    child: list.isEmpty
                        ? BkEmptyState(
                            icon: Icons.storefront_outlined,
                            title: 'No businesses registered yet',
                            subtitle:
                                'List your portable toilets or cold rooms business profile to start renting out units.',
                            actionLabel: 'Register Business',
                            onAction: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateEditBusinessScreen(),
                                ),
                              );
                            },
                          )
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white,
        elevation: 3,
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

  Widget _buildBusinessCard(Business business) {
    final isToilet = business.businessType == BusinessType.TOILET_RENTAL;
    final typeLabel = isToilet ? 'Toilet Hire' : 'Cold Storage';
    final badgeBg = isToilet
        ? AppTheme.primaryColor.withOpacity(0.12)
        : AppTheme.accentColor.withOpacity(0.15);
    final badgeTextColor = isToilet ? AppTheme.primaryColor : const Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusinessDetailScreen(business: business),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.secondaryTextColor),
                      color: AppTheme.surfaceColor,
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
                              Icon(Icons.edit_outlined, size: 18, color: AppTheme.darkTextColor),
                              SizedBox(width: 8),
                              Text('Edit', style: TextStyle(color: AppTheme.darkTextColor)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.darkTextColor,
                  ),
                ),
                if (business.description != null && business.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    business.description!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.secondaryTextColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(color: AppTheme.borderColor, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.secondaryTextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        business.address,
                        style: const TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.phone_outlined, size: 16, color: AppTheme.secondaryTextColor),
                    const SizedBox(width: 6),
                    Text(
                      business.phoneNumber,
                      style: const TextStyle(fontSize: 13, color: AppTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
