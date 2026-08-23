// ignore_for_file: slash_for_doc_comments, deprecated_member_use
import 'package:flutter/material.dart';
import '../customer/browse_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../business/dashboard_screen.dart';

/**
 * Main shell routing authenticated traffic between Browse, My Bookings, and Owner Mode.
 *
 * <p>Wraps a BottomNavigationBar supporting transitions between rentals browsing
 * (index 0), booking history (index 1), and owner portal dashboard (index 2).</p>
 */
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    BrowseScreen(),
    MyBookingsScreen(),
    DashboardScreen(),
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
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'My Bookings',
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
