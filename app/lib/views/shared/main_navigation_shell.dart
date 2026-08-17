// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import '../customer/browse_screen.dart';
import '../business/business_list_screen.dart';

/**
 * Main shell routing authenticated traffic between Customer Mode and Owner Mode.
 *
 * <p>Wraps a BottomNavigationBar supporting transitions between rentals browsing
 * (index 0) and business profiles listing (index 1).</p>
 */
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BrowseScreen(),
    BusinessListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: const Color(0xFF0F0E17),
          selectedItemColor: const Color(0xFF5D5FEF),
          unselectedItemColor: const Color(0xFF94A3B8),
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Browse',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'My Businesses',
            ),
          ],
        ),
      ),
    );
  }
}
